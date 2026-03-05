#!/usr/bin/env python3

import argparse
import itertools
import json
import os
import re
import shutil
import subprocess
import typing
import multiprocessing

NANOSEC_IN_ONE_SEC = 10**9


class Event(typing.TypedDict):
    ts: int
    label: str


def get_events(exec_log: str) -> list[Event]:
    events = []
    with open(exec_log) as file:
        for line_str in file:
            orig_line = line_str
            line_str = line_str.strip()
            if len(line_str) == 0:
                continue
            line = line_str.split(" ")
            ts_str = line[0].replace(".", "")
            if not re.search("^[0-9]*$", ts_str):
                print("ignore line without timestamp: " + orig_line)
                continue
            ts = int(ts_str) * 1000
            line.pop(0)
            label = " ".join(line)
            events.append(Event(ts=ts, label=label))
    if not events:
        raise Exception("no events found in: " + exec_log)
    return events


class Subtrace(typing.TypedDict):
    start: int
    end: int


def sub_traces(events: list[Event], trace_duration: int) -> list[Subtrace]:
    traces = []
    trace_duration *= NANOSEC_IN_ONE_SEC
    first_timestamp = int(events[0]["ts"])
    last_timestamp = int(events[-1]["ts"])
    offset = int(trace_duration / 2)
    ts = first_timestamp + offset
    while ts < last_timestamp + offset:
        start = ts - offset
        end = ts + offset
        has_events = False
        ts += offset
        for e in events:
            if e["ts"] >= start and e["ts"] <= end:
                has_events = True
                break
        if has_events:
            traces.append(Subtrace(start=start, end=end))
    return traces


def generate_one_trace(params: typing.Tuple[Subtrace, str]) -> str:
    trace, traces_dir = params
    ts_start = str(trace["start"])
    start = trace["start"] / NANOSEC_IN_ONE_SEC
    end = trace["end"] / NANOSEC_IN_ONE_SEC
    path = f"{traces_dir}/{ts_start}.gz"
    here = os.getcwd()
    sed_expr = f's#"srcline":"{here}/#"srcline":"#'

    time_range = f"{start}~{end}"

    cmd = f"uftrace dump --chrome --srcline --time-range={start}~{end}"
    cmd += f" | sed -e '{sed_expr}'"
    cmd += f" | gzip -9 > {path}"
    subprocess.check_call(["bash", "-euc", "-o", "pipefail", cmd])
    return cmd


def generate_traces(traces: list[Subtrace], traces_dir: str) -> None:
    num_workers = multiprocessing.cpu_count()
    num_traces = len(traces)
    print(f"generate traces in parallel with {num_workers} workers")
    with multiprocessing.Pool(num_workers) as p:
        traces_ = zip(traces, itertools.repeat(traces_dir))
        for i, cmd in enumerate(p.imap_unordered(generate_one_trace, traces_)):
            print(f"[{i + 1}/{num_traces}] {cmd}")


def copy_sources(sources_dir: str) -> None:
    sources = set()
    for file in os.listdir("uftrace.data"):
        file = "uftrace.data/" + file
        if not file.endswith(".dbg"):
            continue
        with open(file) as dbg:
            for line_str in dbg:
                if not line_str.startswith("L:"):
                    continue
                line = line_str.strip().split(" ")
                source = line[-1]
                if os.path.exists(source):
                    sources.add(source)
    here = os.getcwd()
    print(f"copy sources to {sources_dir}")
    for s in sources:
        s = os.path.realpath(s)
        dest = s.replace(here, sources_dir)
        dest_folder = os.path.dirname(dest)
        if not os.path.exists(dest_folder):
            os.makedirs(dest_folder)
        shutil.copyfile(s, dest)


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="uftrace-web-viewer",
        description="explore uftrace trace",
    )
    parser.add_argument(
        "exec_log",
        nargs="?",
        default="uftrace.data/exec.log",
        help="log of execution with timestamps",
    )
    parser.add_argument(
        "--trace-duration",
        type=float,
        default=1,
        help="duration for one partial trace (seconds)",
    )
    parser.add_argument(
        "--trace-url",
        default="traces",
        help="base url for traces",
    )
    parser.add_argument(
        "--src-url",
        default="sources",
        help="base url for sources",
    )
    args = parser.parse_args()

    if not os.path.exists("uftrace.data"):
        raise Exception("can't find uftrace folder")

    web_dir = "uftrace.data/web"

    events = get_events(args.exec_log)

    traces = sub_traces(events, args.trace_duration)

    traces_dir = web_dir + "/traces"
    if not os.path.exists(traces_dir):
        os.makedirs(traces_dir)
    generate_traces(traces, traces_dir)

    sources_dir = web_dir + "/sources"
    copy_sources(sources_dir)

    json_data = dict(
        events=events, traces=traces, trace_url=args.trace_url, src_url=args.src_url
    )
    json_file = web_dir + "/trace.json"
    with open(json_file, "w") as f:
        json.dump(json_data, f, indent=2)
    print(f"wrote json file {json_file}")


if __name__ == "__main__":
    main()
