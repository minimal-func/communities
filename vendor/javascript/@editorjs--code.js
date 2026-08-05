// @editorjs/code@2.9.4 downloaded from https://ga.jspm.io/npm:@editorjs/code@2.9.4/dist/code.mjs

(function(){try{if(typeof document<"u"){var e=document.createElement("style");e.appendChild(document.createTextNode(".ce-code__textarea{min-height:200px;font-family:Menlo,Monaco,Consolas,Courier New,monospace;color:#41314e;line-height:1.6em;font-size:12px;background:#f8f7fa;border:1px solid #f1f1f4;box-shadow:none;white-space:pre;word-wrap:normal;overflow-x:auto;resize:vertical}")),document.head.appendChild(e)}}catch(e){console.error("vite-plugin-css-injected-by-js",e)}})();function e(e,t){let a="";for(;a!=="\n"&&t>0;)t-=1,a=e.substr(t,1);return a==="\n"&&(t+=1),t}const t='<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="none" viewBox="0 0 24 24"><path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 8L5 12L9 16"/><path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 8L19 12L15 16"/></svg>';
/**
 * CodeTool for Editor.js
 * @version 2.0.0
 * @license MIT
 */class d{
/**
   * Notify core that read-only mode is supported
   * @returns true if read-only mode is supported
   */
static get isReadOnlySupported(){return!0}
/**
   * Allows pressing Enter key to create line breaks inside the CodeTool textarea
   * This enables multi-line input within the code editor.
   * @returns true if line breaks are allowed in the textarea
   */static get enableLineBreaks(){return!0}
/**
   * Render plugin`s main Element and fill it with saved data
   * @param options - tool constricting options
   * @param options.data — previously saved plugin code
   * @param options.config - user config for Tool
   * @param options.api - Editor.js API
   * @param options.readOnly - read only mode flag
   */constructor({data:e,config:t,api:a,readOnly:s}){this.api=a,this.readOnly=s,this.placeholder=this.api.i18n.t(t.placeholder||d.DEFAULT_PLACEHOLDER),this.CSS={baseClass:this.api.styles.block,input:this.api.styles.input,wrapper:"ce-code",textarea:"ce-code__textarea"},this.nodes={holder:null,textarea:null},this.data={code:e.code??""},this.nodes.holder=this.drawView()
/**
   * Return Tool's view
   * @returns this.nodes.holder - Code's wrapper
   */}render(){return this.nodes.holder}
/**
   * Extract Tool's data from the view
   * @param codeWrapper - CodeTool's wrapper, containing textarea with code
   * @returns - saved plugin code
   */save(e){return{code:e.querySelector("textarea").value}}
/**
   * onPaste callback fired from Editor`s core
   * @param event - event with pasted content
   */onPaste(e){switch(e.type){case"tag":{const t=e.detail.data;this.handleHTMLPaste(t);break}}}
/**
   * Returns Tool`s data from private property
   * @returns
   */get data(){return this._data}
/**
   * Set Tool`s data to private property and update view
   * @param data - saved tool data
   */set data(e){this._data=e,this.nodes.textarea&&(this.nodes.textarea.value=e.code)
/**
   * Get Tool toolbox settings.
   * Provides the icon and title to display in the toolbox for the CodeTool.
   * @returns An object containing:
   * - icon: SVG representation of the Tool's icon
   * - title: Title to show in the toolbox
   */}static get toolbox(){return{icon:t,title:"Code"}}
/**
   * Default placeholder for CodeTool's textarea
   * @returns
   */static get DEFAULT_PLACEHOLDER(){return"Enter a code"}
/**
   *  Used by Editor.js paste handling API.
   *  Provides configuration to handle CODE tag.
   * @returns
   */static get pasteConfig(){return{tags:["pre"]}}
/**
   * Automatic sanitize config
   * @returns
   */static get sanitize(){return{code:!0}}
/**
   * Handles Tab key pressing (adds/removes indentations)
   * @param event - keydown
   */tabHandler(t){t.stopPropagation(),t.preventDefault();const a=t.target,s=t.shiftKey,r=a.selectionStart,n=a.value,o="  ";let i;if(s){const t=e(n,r);if(n.substr(t,o.length)!==o)return;a.value=n.substring(0,t)+n.substring(t+o.length),i=r-o.length}else i=r+o.length,a.value=n.substring(0,r)+o+n.substring(r);a.setSelectionRange(i,i)}
/**
   * Create Tool's view
   * @returns
   */drawView(){const e=document.createElement("div"),t=document.createElement("textarea");return e.classList.add(this.CSS.baseClass,this.CSS.wrapper),t.classList.add(this.CSS.textarea,this.CSS.input),t.value=this.data.code,t.placeholder=this.placeholder,this.readOnly&&(t.disabled=!0),e.appendChild(t),t.addEventListener("keydown",(e=>{switch(e.code){case"Tab":this.tabHandler(e);break}})),this.nodes.textarea=t,e
/**
   * Extracts the code content from the pasted element's innerHTML and populates the tool's data.
   * @param element - pasted HTML element
   */}handleHTMLPaste(e){this.data={code:e.innerHTML}}}export{d as default};

