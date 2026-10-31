/* tslint:disable */
/* eslint-disable */

/**
 * The shared benchmark plan, resolved for the browser: the detailed
 * scenarios from `nice_common::bench_defs` (the wasm client has no niceonly
 * path), with start positions resolved against the base ranges. u128 values
 * are carried as strings for the same reason the claim ranges are.
 *
 * The page drives the sweep from this instead of hardcoding windows, so the
 * browser suite and the native `--benchmark` sweep measure identical work
 * by construction.
 */
export function benchmark_plan(): string;

/**
 * The git commit the wasm module was built from, for benchmark reports.
 */
export function build_sha(): string;

/**
 * The workspace client version, so browser submissions carry the real
 * number instead of a string hardcoded in the JS (which had drifted three
 * minor versions behind). The workers append a `-wasm-worker` /
 * `-wasm-webgpu` suffix to keep the paths distinguishable server-side.
 */
export function client_version(): string;

/**
 * Sizes the GPU path actually compiled with, for field diagnosis. The page
 * logs this at startup: a browser caches the wasm aggressively, and without
 * it a console paste cannot tell a fixed build from a stale one.
 */
export function gpu_build_info(): string;

/**
 * Try to bring up WebGPU. Returns the adapter's name (for the backend
 * dropdown) or throws if no adapter is available — the caller treats a
 * rejection as "no GPU option on this browser".
 *
 * The underlying client is initialized once per worker and cheaply cloned
 * by later calls, so this doubles as the warm-up.
 */
export function gpu_init(): Promise<string>;

export function main(): void;

/**
 * The synthetic NiceMark score for a set of measured rates, via the same
 * geometric mean over the same pinned references the native client scores
 * against — a browser and a native run on one machine are directly
 * comparable (the browser just scores lower). Input:
 * `[{"key": "b40_detailed", "rate": 1.5e7}, ...]`. Returns nothing when no
 * scenario matched a reference.
 */
export function nicemark_score(rates_json: string, gpu: boolean): number | undefined;

/**
 * Process a chunk on the GPU with the u32-only WebGPU kernel. Same JSON
 * result shape as [`process_chunk_wasm`], so the merging JS is shared.
 */
export function process_chunk_gpu(range_start_str: string, range_end_str: string, base: number): Promise<string>;

/**
 * Process a chunk of numbers and return nice numbers and distribution updates
 */
export function process_chunk_wasm(range_start_str: string, range_end_str: string, base: number): string;

export type InitInput = RequestInfo | URL | Response | BufferSource | WebAssembly.Module;

export interface InitOutput {
    readonly memory: WebAssembly.Memory;
    readonly benchmark_plan: () => [number, number];
    readonly build_sha: () => [number, number];
    readonly client_version: () => [number, number];
    readonly gpu_build_info: () => [number, number];
    readonly gpu_init: () => any;
    readonly main: () => void;
    readonly nicemark_score: (a: number, b: number, c: number) => [number, number, number, number];
    readonly process_chunk_gpu: (a: number, b: number, c: number, d: number, e: number) => any;
    readonly process_chunk_wasm: (a: number, b: number, c: number, d: number, e: number) => [number, number];
    readonly wasm_bindgen_216610c4f6ea48fe___convert__closures_____invoke___wasm_bindgen_216610c4f6ea48fe___JsValue__core_37ee0ce0c4cd57d5___result__Result_____wasm_bindgen_216610c4f6ea48fe___JsError___true_: (a: number, b: number, c: any) => [number, number];
    readonly wasm_bindgen_216610c4f6ea48fe___convert__closures_____invoke___js_sys_8162bf7536df56dc___Function_fn_wasm_bindgen_216610c4f6ea48fe___JsValue_____wasm_bindgen_216610c4f6ea48fe___sys__Undefined___js_sys_8162bf7536df56dc___Function_fn_wasm_bindgen_216610c4f6ea48fe___JsValue_____wasm_bindgen_216610c4f6ea48fe___sys__Undefined_______true_: (a: number, b: number, c: any, d: any) => void;
    readonly wasm_bindgen_216610c4f6ea48fe___convert__closures_____invoke___wasm_bindgen_216610c4f6ea48fe___JsValue______true_: (a: number, b: number, c: any) => void;
    readonly __wbindgen_malloc: (a: number, b: number) => number;
    readonly __wbindgen_realloc: (a: number, b: number, c: number, d: number) => number;
    readonly __wbindgen_exn_store: (a: number) => void;
    readonly __externref_table_alloc: () => number;
    readonly __wbindgen_externrefs: WebAssembly.Table;
    readonly __wbindgen_free: (a: number, b: number, c: number) => void;
    readonly __wbindgen_destroy_closure: (a: number, b: number) => void;
    readonly __externref_table_dealloc: (a: number) => void;
    readonly __wbindgen_start: () => void;
}

export type SyncInitInput = BufferSource | WebAssembly.Module;

/**
 * Instantiates the given `module`, which can either be bytes or
 * a precompiled `WebAssembly.Module`.
 *
 * @param {{ module: SyncInitInput }} module - Passing `SyncInitInput` directly is deprecated.
 *
 * @returns {InitOutput}
 */
export function initSync(module: { module: SyncInitInput } | SyncInitInput): InitOutput;

/**
 * If `module_or_path` is {RequestInfo} or {URL}, makes a request and
 * for everything else, calls `WebAssembly.instantiate` directly.
 *
 * @param {{ module_or_path: InitInput | Promise<InitInput> }} module_or_path - Passing `InitInput` directly is deprecated.
 *
 * @returns {Promise<InitOutput>}
 */
export default function __wbg_init (module_or_path?: { module_or_path: InitInput | Promise<InitInput> } | InitInput | Promise<InitInput>): Promise<InitOutput>;
