/*
 * Workerd Runtime Type Definitions
 *
 * This file declares TypeScript interfaces and classes that model the
 * JavaScript API surface exposed by the Cloudflare Workerd runtime.  These
 * declarations are distilled from the official documentation and the
 * `workerdouille` codebase.  They include both standard Web APIs and
 * Cloudflare‑specific bindings such as KV storage, Durable Objects, R2
 * buckets, Workers Queues, Email, D1 Databases, Hyperdrive, Analytics, and
 * HTMLRewriter.  The intention is to provide Codex with a concise set
 * of type references that mirror the runtime environment so that new
 * objects can be implemented in Fuzzilli's Workerd profile.  Note that
 * these definitions are simplified and omit many optional fields and
 * overloads; consult the official documentation for complete details.
 */

// -----------------------------------------------------------------------------
// Global Built‑ins
//
// Workerd exposes most standard Web APIs by default.  We declare a few
// here to provide context for the Cloudflare‑specific types below.  These
// declarations mirror the DOM types but are included to make this file
// self‑contained.  If you are using `@types/web` or a DOM lib you may
// prefer to rely on those definitions instead.

declare function fetch(input: RequestInfo | URL, init?: RequestInit): Promise<Response>;
declare function setTimeout(handler: (...args: any[]) => any, timeout?: number, ...args: any[]): number;
declare function clearTimeout(handle?: number): void;
declare function setInterval(handler: (...args: any[]) => any, timeout?: number, ...args: any[]): number;
declare function clearInterval(handle?: number): void;
declare function queueMicrotask(callback: () => void): void;
declare function structuredClone<T>(value: T): T;
declare function btoa(data: string): string;
declare function atob(data: string): string;

// -----------------------------------------------------------------------------
// Standard Web Interfaces (simplified)
//
interface Headers {
  append(name: string, value: string): void;
  delete(name: string): void;
  get(name: string): string | null;
  has(name: string): boolean;
  set(name: string, value: string): void;
  forEach(callback: (value: string, name: string, headers: this) => void): void;
  entries(): IterableIterator<[string, string]>;
  keys(): IterableIterator<string>;
  values(): IterableIterator<string>;
  getAll?(name: string): string[];
  getSetCookie?(): string[];
}

interface Body {
  readonly body: ReadableStream<Uint8Array> | null;
  readonly bodyUsed: boolean;
  arrayBuffer(): Promise<ArrayBuffer>;
  text(): Promise<string>;
  json<T = any>(): Promise<T>;
  blob(): Promise<Blob>;
  formData(): Promise<FormData>;
}

interface RequestInit {
  method?: string;
  headers?: HeadersInit;
  body?: BodyInit | null;
  redirect?: RequestRedirect;
  signal?: AbortSignal | null;
}

interface Request extends Body {
  readonly method: string;
  readonly url: string;
  readonly headers: Headers;
  readonly cf?: any;
  clone(): Request;
}

interface ResponseInit {
  status?: number;
  statusText?: string;
  headers?: HeadersInit;
}

interface Response extends Body {
  readonly headers: Headers;
  readonly status: number;
  readonly statusText: string;
  readonly ok: boolean;
  clone(): Response;
  static redirect(url: string | URL, status?: number): Response;
  static json(data: any, init?: ResponseInit): Response;
}

interface URL {
  readonly href: string;
  readonly origin: string;
  protocol: string;
  username: string;
  password: string;
  host: string;
  hostname: string;
  port: string;
  pathname: string;
  search: string;
  searchParams: URLSearchParams;
  hash: string;
  toString(): string;
  toJSON(): string;
}

interface URLSearchParams {
  append(name: string, value: string): void;
  delete(name: string): void;
  get(name: string): string | null;
  getAll(name: string): string[];
  has(name: string): boolean;
  set(name: string, value: string): void;
  sort(): void;
  forEach(callback: (value: string, name: string, params: this) => void): void;
  entries(): IterableIterator<[string, string]>;
  keys(): IterableIterator<string>;
  values(): IterableIterator<string>;
  [Symbol.iterator](): IterableIterator<[string, string]>;
}

// -----------------------------------------------------------------------------
// HTMLRewriter API
//
/**
 * The HTMLRewriter API provides streaming HTML transformations.  A new
 * HTMLRewriter instance can register handlers for specific CSS selectors
 * or document‑wide events and produces a transformed Response.  Handlers
 * receive Element, Comment, Text and other objects that expose methods to
 * inspect and modify the underlying HTML.
 */
declare class HTMLRewriter {
  /**
   * Register a handler for elements matching the given CSS selector.
   * @param selector CSS selector string
   * @param handlers Object containing callbacks for element, comments or text
   */
  on(selector: string, handlers: ElementContentHandlers): this;
  /**
   * Register handlers that operate on the entire document (doctype, end tags,
   * document end).
   */
  onDocument(handlers: DocumentContentHandlers): this;
  /**
   * Transform an incoming Response by streaming it through the registered
   * handlers, returning a new Response whose body reflects the modifications.
   */
  transform(response: Response): Response;
}

/**
 * Handlers for element content.  Each callback receives an object through
 * which you can inspect and modify the HTML structure.
 */
interface ElementContentHandlers {
  element?(element: Element): void;
  comments?(comment: Comment): void;
  text?(text: Text): void;
}

interface DocumentContentHandlers {
  doctype?(doctype: Doctype): void;
  comments?(comment: Comment): void;
  text?(text: Text): void;
  end?(end: DocumentEnd): void;
}

/** Represents an HTML element within the rewriter. */
interface Element {
  readonly tagName: string;
  getAttribute(name: string): string | null;
  hasAttribute(name: string): boolean;
  setAttribute(name: string, value: string): void;
  removeAttribute(name: string): void;
  prepend(content: string | HTMLRewriterTypes, options?: ContentOptions): void;
  append(content: string | HTMLRewriterTypes, options?: ContentOptions): void;
  setInnerContent(content: string | HTMLRewriterTypes, options?: ContentOptions): void;
  setOuterContent(content: string | HTMLRewriterTypes, options?: ContentOptions): void;
  remove(): void;
  before(content: string | HTMLRewriterTypes, options?: ContentOptions): void;
  after(content: string | HTMLRewriterTypes, options?: ContentOptions): void;
  /** Iterate attributes as [name, value] pairs */
  attributes: IterableIterator<{ name: string; value: string; namespace?: string }>;
}

/** Represents an HTML comment. */
interface Comment {
  readonly text: string;
  remove(): void;
  before(content: string | HTMLRewriterTypes, options?: ContentOptions): void;
  after(content: string | HTMLRewriterTypes, options?: ContentOptions): void;
  replace(content: string | HTMLRewriterTypes, options?: ContentOptions): void;
}

/** Represents a text node. */
interface Text {
  readonly text: string;
  readonly lastInTextNode: boolean;
  remove(): void;
  before(content: string | HTMLRewriterTypes, options?: ContentOptions): void;
  after(content: string | HTMLRewriterTypes, options?: ContentOptions): void;
  replace(content: string | HTMLRewriterTypes, options?: ContentOptions): void;
  split(offset: number): void;
}

/** Represents a document doctype. */
interface Doctype {
  readonly name: string;
  readonly publicId: string;
  readonly systemId: string;
}

/** Called when the parser reaches the end of the document. */
interface DocumentEnd {
  onEnd(): void;
}

/** Additional types accepted by HTMLRewriter content insertion methods. */
type HTMLRewriterTypes = string | ArrayBuffer | ReadableStream<any>;

/** Options controlling how content is inserted by the rewriter. */
interface ContentOptions {
  html?: boolean;
  /** If true, content is interpreted as text rather than HTML */
  text?: boolean;
}

// -----------------------------------------------------------------------------
// Cloudflare KV Storage
//
/**
 * A binding to a Workers KV namespace.  This interface represents the
 * methods available on `KVNamespace` for reading and writing key/value pairs.
 */
interface KVNamespace {
  /** Retrieve a value by key.  The `type` option controls how the value is
   * deserialized; when omitted, the default is "text" which returns a
   * string or null if the key does not exist.  When `type` is "json", the
   * return type is `any` (parsed JSON).  Passing an array of keys returns a
   * `Map` from key to value.  */
  get<T = string>(key: string, options?: KVGetOptions): Promise<T | null>;
  get<T = string>(keys: string[], options?: KVGetOptions): Promise<Map<string, T | null>>;
  /** Retrieve a value and its metadata.  Returns an object with fields
   * `value` and `metadata` if present.  Passing an array returns a map. */
  getWithMetadata<T = string, M = unknown>(key: string, options?: KVGetOptions): Promise<{ value: T | null; metadata: M | null; } | null>;
  getWithMetadata<T = string, M = unknown>(keys: string[], options?: KVGetOptions): Promise<Map<string, { value: T | null; metadata: M | null; } | null>>;
  /** Store a value.  Accepts strings, ArrayBuffers, Uint8Arrays and
   * ReadableStreams.  Options allow setting expiration (in seconds or as a
   * Date), and custom metadata.  */
  put(key: string, value: string | ArrayBuffer | ArrayBufferView | ReadableStream<any> | null, options?: KVPutOptions): Promise<void>;
  /** Delete a single key */
  delete(key: string): Promise<boolean | void>;
  /** Delete multiple keys at once (experimental) */
  delete(keys: string[]): Promise<number | void>;
  /** List keys in the namespace.  Options control prefix, limit and cursor. */
  list(options?: KVListOptions): Promise<KVListResult>;
}

interface KVGetOptions {
  type?: 'text' | 'json' | 'arrayBuffer' | 'stream';
  cacheTtl?: number;
}

interface KVPutOptions {
  expiration?: number;
  expirationTtl?: number;
  metadata?: any;
}

interface KVListOptions {
  prefix?: string;
  limit?: number;
  cursor?: string;
}

interface KVListResult {
  keys: { name: string; expiration?: number; metadata?: any; }[];
  cursor?: string;
  list_complete?: boolean;
}

// -----------------------------------------------------------------------------
// Durable Objects API
//
/**
 * A binding to a Durable Object class.  Use this namespace to generate
 * identifiers and obtain stubs to remote Durable Object instances.
 */
interface DurableObjectNamespace {
  /** Return a new unique ID for creating a new object instance. */
  newUniqueId(options?: DurableObjectIdOptions): DurableObjectId;
  /** Derive a deterministic ID from a human‑readable name. */
  idFromName(name: string): DurableObjectId;
  /** Parse an ID from its hex string representation. */
  idFromString(id: string): DurableObjectId;
  /** Return a stub for an object by ID.  An optional location hint may be
   * provided to route the request to a specific jurisdiction. */
  get(id: DurableObjectId, options?: DurableObjectGetOptions): DurableObjectStub;
  /** Create or retrieve a stub by name.  Equivalent to `idFromName` + `get`. */
  getByName(name: string, options?: DurableObjectGetOptions): DurableObjectStub;
  /** (Optional) Return a stub only if the object already exists. */
  getExisting?(id: DurableObjectId, options?: DurableObjectGetOptions): DurableObjectStub | null;
  /** Restrict this namespace to a specific jurisdiction (EU, FedRAMP, etc). */
  jurisdiction(region: string): DurableObjectNamespace;
}

interface DurableObjectId {
  readonly name?: string;
  toString(): string;
  equals(other: DurableObjectId): boolean;
  readonly jurisdiction?: string;
}

interface DurableObjectIdOptions {
  jurisdiction?: string;
}

interface DurableObjectGetOptions {
  locationHint?: string;
  allowConcurrency?: boolean;
}

/** A proxy to a remote Durable Object.  Implements the Fetcher interface. */
interface DurableObjectStub {
  readonly id: DurableObjectId;
  readonly name?: string;
  fetch(request: Request): Promise<Response>;
  // Some runtimes also allow calling stub.fetch(url: string | Request, init?: RequestInit)
  fetch(url: string, init?: RequestInit): Promise<Response>;
}

/**
 * The state passed to a Durable Object constructor.  Provides storage and
 * concurrency primitives as well as WebSocket acceptance in server DOs.
 */
interface DurableObjectState {
  readonly id: DurableObjectId;
  readonly storage: DurableObjectStorage;
  waitUntil(promise: Promise<any>): void;
  blockConcurrencyWhile<T>(callback: () => Promise<T>): Promise<T>;
  // WebSocket control methods (server DO mode only)
  acceptWebSocket?(socket: WebSocket, tags?: string[]): void;
  getWebSockets?(tag?: string): WebSocket[];
  setWebSocketAutoResponse?(pair: WebSocketRequestResponsePair): void;
  getWebSocketAutoResponse?(): WebSocketRequestResponsePair | null;
  getWebSocketAutoResponseTimestamp?(socket: WebSocket): number | null;
  setHibernatableWebSocketEventTimeout?(milliseconds: number): void;
  getTags?(socket: WebSocket): string[];
  abort?(reason?: string): void;
}

/**
 * Persistent key/value store scoped to a Durable Object.  Supports atomic
 * transactions and scheduling alarms.
 */
interface DurableObjectStorage {
  get<T = any>(key: string | string[]): Promise<T | undefined | Map<string, T>>;
  put(key: string, value: any): Promise<void>;
  put(entries: Record<string, any>): Promise<void>;
  delete(key: string | string[]): Promise<boolean | number>;
  deleteAll(): Promise<void>;
  list<T = any>(options?: DurableObjectListOptions): Promise<Map<string, T>>;
  transaction<T>(callback: (txn: DurableObjectTransaction) => Promise<T>): Promise<T>;
  transactionSync?<T>(callback: (txn: DurableObjectTransaction) => T): T;
  getAlarm(): Promise<number | null>;
  setAlarm(time: number | Date): Promise<void>;
  deleteAlarm(): Promise<void>;
  // Advanced consistency/bookmark methods omitted for brevity
  // Experimental properties for SQL/kv access
  readonly sql?: SqlStorage;
  readonly kv?: SyncKvStorage;
}

interface DurableObjectListOptions {
  start?: string;
  end?: string;
  prefix?: string;
  limit?: number;
  reverse?: boolean;
}

/** A transaction on DurableObjectStorage.  Operations are staged until commit. */
interface DurableObjectTransaction {
  get<T = any>(key: string | string[]): Promise<T | undefined | Map<string, T>>;
  put(key: string, value: any): Promise<void>;
  put(entries: Record<string, any>): Promise<void>;
  delete(key: string | string[]): Promise<boolean | number>;
  list<T = any>(options?: DurableObjectListOptions): Promise<Map<string, T>>;
  rollback(): void;
  getAlarm(): Promise<number | null>;
  setAlarm(time: number | Date): Promise<void>;
  deleteAlarm(): Promise<void>;
}

// Experimental synchronous key/value interface for DO storage
interface SyncKvStorage {
  get<T = any>(key: string | string[]): T | undefined | Map<string, T>;
  put(key: string, value: any): void;
  put(entries: Record<string, any>): void;
  delete(key: string | string[]): boolean | number;
  list<T = any>(options?: DurableObjectListOptions): Map<string, T>;
}

interface SqlStorage {
  // A synchronous SQL database handle (e.g. SQLite) available to DOs.
  exec<T = any>(query: string, params?: any[]): T[];
  prepare(query: string): SqlPreparedStatement;
}

interface SqlPreparedStatement {
  bind(...params: any[]): this;
  run<T = any>(): T[];
  finalize(): void;
}

// -----------------------------------------------------------------------------
// Workers Queues API
//
/**
 * A binding representing a Cloudflare Queue.  Used to enqueue messages.
 */
interface WorkerQueue {
  /** Send a single message to the queue.  The message body will be serialized
   * according to the `contentType` option (`json`, `text`, `bytes`, or `v8`).
   * The `delaySeconds` option can schedule the message for later delivery. */
  send(message: any, options?: QueueSendOptions): Promise<void>;
  /** Send multiple messages in a batch.  An iterable of objects may include
   * per‑message body, contentType and delaySeconds overrides. */
  sendBatch(messages: Iterable<QueueSendRequest>, options?: QueueBatchOptions): Promise<void>;
}

interface QueueSendOptions {
  contentType?: 'json' | 'text' | 'bytes' | 'v8';
  delaySeconds?: number;
}

interface QueueBatchOptions extends QueueSendOptions {}

interface QueueSendRequest extends QueueSendOptions {
  body: any;
}

/**
 * Event dispatched when a worker consumes messages from a Queue.  The
 * event contains an array of messages and methods to ack or retry them.
 */
interface QueueEvent extends ExtendableEvent {
  readonly type: 'queue';
  readonly queue: string;
  readonly messages: QueueMessage[];
  retryAll(options?: { delaySeconds?: number }): void;
}

/** Represents a single message delivered to a worker via a QueueEvent. */
interface QueueMessage {
  readonly id: string;
  readonly timestamp: Date;
  readonly body: any;
  readonly attempts: number;
  ack(): void;
  retry(options?: { delaySeconds?: number }): void;
}

// -----------------------------------------------------------------------------
// Workers Email API
//
/**
 * Represents an outbound or inbound email.  For outgoing email, construct
 * EmailMessage with from/to/raw.  For inbound email (EmailEvent), the
 * message is a ForwardableEmailMessage which adds headers and forwarding
 * methods.
 */
interface EmailMessage {
  from: string;
  to: string;
  raw: ReadableStream<any> | string;
}

interface ForwardableEmailMessage extends EmailMessage {
  readonly headers: Headers;
  readonly rawSize: number;
  setReject(reason: string): void;
  forward(rcptTo: string, headers?: Headers): Promise<void>;
  reply(message: EmailMessage): Promise<void>;
}

/** Event representing an inbound email to a worker. */
interface EmailEvent extends ExtendableEvent {
  readonly type: 'email';
  readonly message: ForwardableEmailMessage;
}

/** Binding used to send email from a worker. */
interface SendEmailBinding {
  send(message: EmailMessage): Promise<void>;
}

// -----------------------------------------------------------------------------
// Analytics Engine API
//
/**
 * Binding to the Cloudflare Analytics Engine.  Allows writing analytic
 * events consisting of numeric, text and blob fields.  The exact format
 * depends on the configured analytics dataset.
 */
interface AnalyticsEngine {
  writeData(event: Record<string, number | string | boolean | ArrayBuffer>): Promise<void>;
}

// -----------------------------------------------------------------------------
// R2 Object Storage API
//
/**
 * A bound R2 bucket provides methods for reading and writing objects.  These
 * signatures are adapted from the Workers API reference.  In addition to
 * basic CRUD operations, R2 supports multipart uploads and listing.
 */
interface R2Bucket {
  /** Retrieve object metadata only. */
  head(key: string): Promise<R2Object | null>;
  /** Retrieve an object.  If the object does not exist, returns null.  If
   * preconditions fail, returns an R2Object without a body. */
  get(key: string, options?: R2GetOptions): Promise<R2ObjectBody | R2Object | null>;
  /** Store a value under the given key.  Accepts a stream, ArrayBuffer,
   * Uint8Array, string or null.  Returns the object metadata or null if
   * preconditions fail. */
  put(key: string, value: ReadableStream<any> | ArrayBuffer | ArrayBufferView | string | null | Blob, options?: R2PutOptions): Promise<R2Object | null>;
  /** Delete one or more keys.  Returns void. */
  delete(key: string | string[]): Promise<void>;
  /** List objects in the bucket.  Returns a paginated result. */
  list(options?: R2ListOptions): Promise<R2Objects>;
  /** Create a multipart upload. */
  createMultipartUpload(key: string, options?: R2MultipartOptions): Promise<R2MultipartUpload>;
  /** Resume an existing multipart upload. */
  resumeMultipartUpload(key: string, uploadId: string): R2MultipartUpload;
}

interface R2Object {
  key: string;
  version: string;
  size: number;
  etag: string;
  httpEtag: string;
  uploaded: Date;
  httpMetadata: R2HTTPMetadata;
  customMetadata: Record<string, string>;
  range?: R2Range;
  checksums?: R2Checksums;
  writeHttpMetadata(headers: Headers): void;
  storageClass: 'Standard' | 'InfrequentAccess';
  ssecKeyMd5?: string;
}

interface R2ObjectBody extends R2Object {
  body: ReadableStream<any>;
  bodyUsed: boolean;
  arrayBuffer(): Promise<ArrayBuffer>;
  text(): Promise<string>;
  json<T = any>(): Promise<T>;
  blob(): Promise<Blob>;
}

interface R2MultipartUpload {
  uploadId: string;
  key: string;
  abort(): Promise<void>;
  complete(parts: R2UploadedPart[]): Promise<R2Object>;
  putPart(partNumber: number, value: ReadableStream<any> | ArrayBuffer | ArrayBufferView | string | null | Blob, options?: R2MultipartPartOptions): Promise<R2UploadedPart>;
}

interface R2UploadedPart {
  partNumber: number;
  etag: string;
}

interface R2GetOptions {
  onlyIf?: Headers;
  range?: Headers;
}

interface R2PutOptions {
  onlyIf?: Headers;
  httpMetadata?: Headers;
  customMetadata?: Record<string, string>;
  md5?: ArrayBuffer;
  sha1?: ArrayBuffer;
  sha256?: ArrayBuffer;
  ssecKey?: ArrayBuffer;
  ssecKeyMd5?: ArrayBuffer;
}

interface R2ListOptions {
  prefix?: string;
  limit?: number;
  cursor?: string;
}

interface R2Objects {
  objects: R2Object[];
  truncated: boolean;
  cursor?: string;
}

interface R2MultipartOptions {
  httpMetadata?: Headers;
  customMetadata?: Record<string, string>;
  // Additional multipart options omitted for brevity
}

interface R2MultipartPartOptions {
  md5?: ArrayBuffer;
  sha1?: ArrayBuffer;
  sha256?: ArrayBuffer;
  ssecKey?: ArrayBuffer;
  ssecKeyMd5?: ArrayBuffer;
}

interface R2Range {
  offset: number;
  length?: number;
}

interface R2Checksums {
  md5?: string;
  sha1?: string;
  sha256?: string;
  sha384?: string;
  sha512?: string;
}

interface R2HTTPMetadata {
  contentType?: string;
  contentLanguage?: string;
  contentEncoding?: string;
  contentDisposition?: string;
  contentMD5?: string;
  cacheControl?: string;
  // Additional HTTP metadata fields omitted
}

// -----------------------------------------------------------------------------
// D1 Database API
//
/**
 * A binding representing a Cloudflare D1 database.  Provides methods to
 * prepare and execute SQL statements, batch queries, run direct exec
 * operations and create consistent sessions.
 */
interface D1Database {
  prepare(query: string): D1PreparedStatement;
  batch(statements: D1PreparedStatement[]): Promise<D1Result<any>[]>;
  exec(query: string): Promise<D1ExecResult>;
  dump?(): Promise<ArrayBuffer>;
  withSession(consistency?: D1SessionConsistency | D1SessionBookmark): D1DatabaseSession;
}

interface D1DatabaseSession {
  prepare(query: string): D1PreparedStatement;
  batch(statements: D1PreparedStatement[]): Promise<D1Result<any>[]>;
  getBookmark(): string | null;
}

interface D1PreparedStatement {
  bind(...values: any[]): D1PreparedStatement;
  first<T = any>(column?: string): Promise<T | null>;
  run(): Promise<D1ExecResult>;
  all<T = any>(): Promise<D1Result<T>>;
  raw<T = any>(options?: { columnNames?: boolean }): Promise<any>;
}

interface D1Result<T> {
  success: true;
  results: T[];
  meta: D1Meta;
  error?: never;
}

interface D1Meta {
  duration: number;
  count?: number;
  changes?: number;
  lastRowId?: number;
}

interface D1ExecResult {
  count: number;
  duration: number;
}

type D1SessionConsistency = 'strong' | 'eventual' | 'first-primary' | 'first-unconstrained';
type D1SessionBookmark = string;

// -----------------------------------------------------------------------------
// Hyperdrive API
//
/**
 * Binding to a Hyperdrive instance (the underlying connection for D1).  Hyperdrive
 * exposes a connection string and connection credentials, and allows
 * establishing a socket to the database.  Typically used internally by
 * database clients; most developers will interact via D1Database instead.
 */
interface Hyperdrive {
  readonly connectionString: string;
  readonly host: string;
  readonly port: number;
  readonly user: string;
  readonly password: string;
  readonly database: string;
  connect(): Promise<Socket>;
}

// -----------------------------------------------------------------------------
// WebSocket API
//
declare class WebSocket extends EventTarget {
  constructor(urlOrPair?: string | URL, protocols?: string | string[]);
  readonly readyState: number;
  readonly url: string;
  readonly protocol: string;
  readonly extensions: string;
  accept(): void;
  send(data: string | ArrayBuffer | ArrayBufferView | Blob): void;
  close(code?: number, reason?: string): void;
  // Internal methods for DO auto response
  serializeAttachment?(): any;
  deserializeAttachment?(data: any): void;
  // Event handlers
  onopen: ((event: Event) => any) | null;
  onmessage: ((event: MessageEvent) => any) | null;
  onerror: ((event: Event) => any) | null;
  onclose: ((event: CloseEvent) => any) | null;
  static readonly CONNECTING: number;
  static readonly OPEN: number;
  static readonly CLOSING: number;
  static readonly CLOSED: number;
}

declare class WebSocketPair {
  constructor();
  readonly 0: WebSocket;
  readonly 1: WebSocket;
  [Symbol.iterator](): Iterator<WebSocket>;
}

/** Used for auto responding to WebSocket messages inside DOs. */
interface WebSocketRequestResponsePair {
  readonly request: string;
  readonly response: string;
}

// -----------------------------------------------------------------------------
// Other Utility Interfaces
//
interface Navigator {
  readonly userAgent: string;
  readonly hardwareConcurrency: number;
  readonly language?: string;
  readonly languages?: string[];
  sendBeacon(url: string | URL, data?: any): boolean;
}

interface Performance {
  readonly timeOrigin: number;
  now(): number;
}

declare const navigator: Navigator;
declare const performance: Performance;
declare const console: Console;

interface Console {
  log(...args: any[]): void;
  info(...args: any[]): void;
  debug(...args: any[]): void;
  warn(...args: any[]): void;
  error(...args: any[]): void;
  assert(condition?: boolean, ...args: any[]): void;
  trace(...args: any[]): void;
  group(...args: any[]): void;
  groupEnd(...args: any[]): void;
}

// ExtendableEvent base for queue and email events
interface ExtendableEvent extends Event {
  waitUntil(promise: Promise<any>): void;
}

// DOM Event definitions (simplified)
interface Event {
  readonly type: string;
  readonly target: EventTarget | null;
  readonly currentTarget: EventTarget | null;
  readonly defaultPrevented: boolean;
  preventDefault(): void;
  stopPropagation(): void;
  stopImmediatePropagation(): void;
}

interface EventTarget {
  addEventListener(type: string, listener: EventListenerOrEventListenerObject | null, options?: boolean | AddEventListenerOptions): void;
  removeEventListener(type: string, listener: EventListenerOrEventListenerObject | null, options?: boolean | EventListenerOptions): void;
  dispatchEvent(event: Event): boolean;
}

interface EventListener {
  (evt: Event): void;
}

interface EventListenerObject {
  handleEvent(evt: Event): void;
}

type EventListenerOrEventListenerObject = EventListener | EventListenerObject;

interface AddEventListenerOptions {
  capture?: boolean;
  once?: boolean;
  passive?: boolean;
  signal?: AbortSignal;
}

interface EventListenerOptions {
  capture?: boolean;
}