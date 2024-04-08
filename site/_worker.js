import * as imports from "./index_bg.js";
export * from "./index_bg.js";
import wkmod from "./index_bg.wasm";
import * as nodemod from "./index_bg.wasm";

if (typeof process !== "undefined" && process.release.name === "node") {
  imports.__wbg_set_wasm(nodemod);
} else {
  const instance = new WebAssembly.Instance(wkmod, {
    "./index_bg.js": imports,
  });
  imports.__wbg_set_wasm(instance.exports); 
}

Error.stackTraceLimit = Infinity;

imports.start?.();

export * as default from "./index_bg.js"