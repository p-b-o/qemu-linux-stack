/**
 * ACE code editor global variable
 * @type import('ace-code')
 */
var ace;

/**
 * Hold base url for sources.
 * Needed because perfetto will call indirectly view_source.
 * @type {string}
 */
var SOURCES_BASE_URL;

/**
 * @typedef Subtrace
 * @property {number} start - timestamp at start
 * @property {number} end - timestamp at end
 *
 * @typedef Trace
 * @property {Subtrace[]} traces - subtraces included in trace
 * @property {TraceEvent[]} events - events included in trace
 * @property {string} src_url - sources base url
 * @property {string} trace_url - subtraces base url
 *
 * @typedef TraceEvent
 * @property {number} ts - timestamp for event
 * @property {string} label
 *
 * @typedef PerfettoStartupCommand
 * @property {string} id
 * @property {string[]} args
 */

/* Display a source file. Called (externally) on slice load in perfetto. */
async function view_source(/** @type string */ url) {
	const orig_url = url;
	const url_components = url.split(":");
	let line_str = url_components[url_components.length - 1];
	if (!line_str) {
		line_str = "0";
	}
	const line = parseInt(line_str, 10);
	url_components.pop();
	let file = url_components.join(":");
	file = `${SOURCES_BASE_URL}/${file}`;
	console.log(`"source: ${file}"`);
	const full_url = `./?action=view-source&source=${orig_url}&base-url=${SOURCES_BASE_URL}`;

	const response = await fetch(file);
	const blob = await response.blob();
	const src = await blob.text();
	const source_viewer = ace.edit(document.getElementById("source_viewer"));
	source_viewer.resize(true);
	source_viewer.setReadOnly(true);
	source_viewer.session.setMode("ace/mode/c_cpp");
	source_viewer.setValue(src);
	source_viewer.scrollToLine(line, true, true, () => {});
	source_viewer.gotoLine(line, 0, true);

	const src_url = document.getElementById("source_url");
	if (!src_url) {
		console.assert(src_url != null, "missing source_url element");
		return;
	}
	src_url.setAttribute("href", full_url);
	file = file.replace(SOURCES_BASE_URL, "");
	if (file.startsWith("/")) {
		file = file.substring(1);
	}
	src_url.textContent = `${file}:${line}`;
}

/* Return html fragment for a given trace. */
function element_trace(
	/** @type Trace */ trace,
	/** @type string */ trace_url,
	/** @type number */ ts,
	/** @type Subtrace|null */ subtrace,
) {
	function html_escape(/** @type {string} */ str) {
		return str
			.replaceAll("&", "&amp;")
			.replaceAll("<", "&lt;")
			.replaceAll(">", "&gt;")
			.replaceAll("'", "&apos;")
			.replaceAll('"', "&quot;");
	}

	function link_event(/** @type number */ ts) {
		return `/?action=view-event&timestamp=${ts}&trace=${trace_url}`;
	}

	function one_event(/** @type TraceEvent */ e) {
		let e_class = "";
		if (subtrace) {
			if (e.ts === ts) {
				e_class = "main_event";
			} else if (subtrace.start <= e.ts && subtrace.end >= e.ts) {
				e_class = "included_event";
			}
		}
		return `<a class="event ${e_class}" href="${link_event(e.ts)}">${html_escape(e.label)}</a>`;
	}

	return `<pre>${trace.events.map((e) => one_event(e)).join("\n")}</pre>`;
}

function find_subtrace(/** @type number */ ts, /** @type Trace */ trace) {
	for (const subtrace of trace.traces) {
		if (subtrace.start <= ts && subtrace.end >= ts) {
			return subtrace;
		}
	}
	return null;
}

function perfetto_url(
	/** @type number */ ts,
	/** @type Subtrace|null */ subtrace,
	/** @type Trace */ trace,
	/** @type string */ trace_url,
) {
	if (!subtrace) {
		return "";
	}
	let url = `${trace.trace_url}/${subtrace.start}.gz`;
	if (!url.startsWith("http")) {
		// perfetto wants to have a full URL
		const trace_dir = trace_url.substring(0, trace_url.lastIndexOf("/"));
		url = `${trace_dir}/${url}`;
		if (!url.startsWith("http")) {
			url = `${window.location.origin}/${url}`;
		}
	}

	console.log(`trace: ${url}`);
	/** @type PerfettoStartupCommand[] */
	const commands = [
		{
			id: "dev.perfetto.SetTimestampFormatMilliseconds",
			args: [],
		},
	];

	for (const e of trace.events) {
		if (e.ts < subtrace.start || e.ts > subtrace.end) {
			continue;
		}
		let color = "#dddddd";
		if (ts === e.ts) {
			color = "#ff7777";
		}
		commands.push({
			id: "dev.perfetto.AddNoteAtTimestamp",
			args: [e.ts.toString(), e.label, color],
		});
	}

	const millisec = 1000 * 1000;
	const start = ts - millisec;
	const end = ts + millisec;

	const startup_commands = encodeURIComponent(JSON.stringify(commands));
	url =
		"perfetto/#!/?url=" +
		url +
		"&visStart=" +
		start +
		"&visEnd=" +
		end +
		"&ts=" +
		ts +
		"&mode=embedded" +
		"&startupCommands=" +
		startup_commands;
	return url;
}

async function fetch_trace(/** @type string */ trace_url) {
	const response = await fetch(trace_url);
	return response.json();
}

async function page_trace(/** @type string|null */ trace_url) {
	if (!trace_url) {
		throw "trace_url";
	}
	const trace = await fetch_trace(trace_url);

	document.body.innerHTML = `
    <h1>Select where to start</h1>
    ${element_trace(trace, trace_url, 0, null)}
    `;
}

async function page_source(
	/** @type string|null */ base_url,
	/** @type string|null */ source_url,
) {
	if (!base_url || !source_url) {
		throw "missing base_url or source_url";
	}
	SOURCES_BASE_URL = base_url;
	document.body.innerHTML = `
    <div class="fullscreen_source_viewer" id="source_viewer"></div>
    <a href="" id="source_url" target="_blank"></a>
    `;
	view_source(source_url);
}

async function page_event(
	/** @type number */ ts,
	/** @type string|null */ trace_url,
) {
	if (!trace_url) {
		throw "missing trace_url";
	}
	const trace = await fetch_trace(trace_url);

	SOURCES_BASE_URL = trace.src_url;
	if (!SOURCES_BASE_URL.startsWith("http")) {
		const trace_dir = trace_url.substring(0, trace_url.lastIndexOf("/"));
		SOURCES_BASE_URL = `${trace_dir}/${trace.src_url}`;
	}
	console.log(`source_base_url: ${SOURCES_BASE_URL}`);

	const subtrace = find_subtrace(ts, trace);

	document.body.innerHTML = `
    <div style="display:flex">
        <div class="left">
            <iframe class="viewer" id="perfetto" src="${perfetto_url(ts, subtrace, trace, trace_url)}"></iframe>
        </div>
        <div class="right">
            ${element_trace(trace, trace_url, ts, subtrace)}
        </div>
    </div>
    <div class="embedded_source_viewer" id="source_viewer"></div>
    <a href="" id="source_url" target="_blank"></a>
    `;

	document.getElementsByClassName("main_event")[0]?.scrollIntoView();
	// enable keyboard zoom by focusing on perfetto
	document.getElementById("perfetto")?.focus();
}

function _main() {
	const params = new URLSearchParams(document.location.search);
	const action = params.get("action");
	if (action === "view-trace") {
		const trace_url = params.get("trace");
		page_trace(trace_url);
	} else if (action === "view-event") {
		const ts = Number(params.get("timestamp"));
		const trace_url = params.get("trace");
		page_event(ts, trace_url);
	} else if (action === "view-source") {
		const base_url = params.get("base-url");
		const source_url = params.get("source");
		page_source(base_url, source_url);
	}
}
