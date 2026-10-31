// Serve the built site (web/search with pkg/ and vendor/, or NICE_E2E_ROOT)
// on 127.0.0.1 until killed, for opening the page by hand.
//
//   node serve.mjs [--port 8000]
import { parseArgs, serve, siteRoot } from "./lib.mjs";

const args = parseArgs();
const site = await serve(siteRoot(), Number(args.port ?? 0));
console.log(`serving ${siteRoot()} at ${site.url} (blank module page: ${site.url}blank.html)`);
