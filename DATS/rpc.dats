staload "prelude/SATS/unsafe.sats"
staload "contrib/jansson/SATS/jansson.sats"
staload "contrib/libevent/SATS/libevent.sats"
staload "contrib/task/SATS/task.sats"
staload "contrib/bitcoin/SATS/base64.sats"
staload "contrib/bitcoin/SATS/rpc.sats"

#define ATS_DYNLOADFLAG 0 // no need for dynloading at run-time

fn get_request_input_string (req: !evhttp_request1): [l:agz] strptr l = let
  extern fun __strndup {l:agz} (str: !strptr l, n: size_t): [l2:agz] strptr l2 = "mac#strndup"
  val (pff_buffer | buffer) = evhttp_request_get_input_buffer(req)
  val len = evbuffer_get_length(buffer)
  val (pff_src | src) = evbuffer_pullup(buffer, ssize_of_int(~1))
  val r = __strndup(src, len)
  prval () = pff_src(src)
  prval () = pff_buffer(buffer)
in
  r
end

dataviewtype rpc_data (lc:addr) = rpc_data_container (lc) of (evhttp_connection lc, rpc_callback)

fun handle_rpc {l:agz} (client: !evhttp_request1, c: rpc_data l):void = let
  val ~rpc_data_container (cn, cb) = c
  val code = if evhttp_request_isnot_null (client) then evhttp_request_get_response_code(client) else 501
in
  if code = HTTP_OK then {
    val result = get_request_input_string (client)
    var e: json_error_t? 
    val json = json_loads(castvwtp1 {string} (result), 0, e);
    val () = cb ((if ~json then rpc_result_json json else rpc_result_error json): rpc_result1)
    val () = cloptr_free (cb)
    val () = bitcoinrpc_disconnect (cn)
    val () = strptr_free (result)
  }
  else {
    val () = cb (rpc_result_http_error (code))
    val () = cloptr_free (cb)
    val () = bitcoinrpc_disconnect (cn)
  }
end

typedef evhttp_callback (t1:viewt@ype) = (!evhttp_request1, t1) -> void
extern fun evhttp_request_new {a:viewt@ype} (callback: evhttp_callback (a), arg: a): evhttp_request0 = "mac#evhttp_request_new"

implement bitcoinrpc_fun (base, url, auth, json, cb) = {
  val uri = evhttp_uri_parse (url)
  val () = assertloc (~uri)

  val (pff_host | host) = evhttp_uri_get_host (uri)
  val () = assertloc (strptr_isnot_null (host))

  val (pff_path | path) = evhttp_uri_get_path (uri)
  val () = assertloc (strptr_isnot_null (path))

  val [lc:addr] cn = bitcoinrpc_connect (base, url)
  val () = assertloc (~cn)

  (* Copy a reference to the connection so we can pass it to the callback when the request is made *)
  val c = __ref (cn) where { extern castfn __ref {l:agz} (b: !evhttp_connection l): evhttp_connection l }
  val container = rpc_data_container (c, cb)

  val client = evhttp_request_new {rpc_data lc} (handle_rpc, container) 
  val () = assertloc (~client)

  val (pff_headers | headers) = evhttp_request_get_output_headers(client)
  val r = evhttp_add_header(headers, "Host", castvwtp1 {string} (host))
  val () = assertloc (r = 0)

  val r = evhttp_add_header(headers, "Content-Type", "application/json")
  val () = assertloc (r = 0)

  val auth = string_to_base64 (auth)
  val () = assertloc (strptr_isnot_null (auth))
  val auth1 = string1_of_string (castvwtp1 {string} (auth))
  val authorization = string1_append ("Basic ", auth1)
  val authorization = strptr_of_strbuf authorization
  val r = evhttp_add_header(headers, "Authorization", castvwtp1 {string} (authorization))
  val () = assertloc (r = 0)
  val () = strptr_free (authorization)
  val () = strptr_free (auth)

  val (pff_buffer | buffer) = evhttp_request_get_output_buffer (client)
  val s = string1_of_string (json)
  val r = evbuffer_add_string (buffer, s, string1_length (s))
  val () = assertloc (r = 0)
  prval () = pff_buffer (buffer)

  val r = evhttp_make_request(cn, client, EVHTTP_REQ_POST, castvwtp1 {string} (path))
  val () = assertloc (r = 0)

  (* The connection is freed when the callback for the request is handled *)
  prval () = __unref (cn) where { extern prfun __unref {l:agz} (b: evhttp_connection l): void }

  prval () = pff_path (path)
  prval () = pff_host (host)
  prval () = pff_headers (headers)
  val () = evhttp_uri_free (uri)
}

implement bitcoinrpc_string (base, url, auth, json) = let
  val tsk = global_scheduler_halt ()
  var result: rpc_result1
  prval (pff, pf) = __borrow (view@ result) where {
                      extern prfun __borrow {l:addr} (r: !rpc_result1? @ l >> (rpc_result1 @ l))
                                      : (rpc_result1 @ l -<lin,prf> void, rpc_result1? @ l)
                    }
  val () = bitcoinrpc_fun (base, url, auth, json, llam (r) => {
                                val () = global_scheduler_queue_task (tsk)
                                val () = result := r
                                prval () = pff (pf)
                              })
  val () = global_scheduler_resume ()
in
  result
end
 
implement bitcoinrpc_strptr (base, url, auth, json) = let
  val r = bitcoinrpc_string (base, url, auth, castvwtp1 {string} {strptr1} (json))
  val () = strptr_free (json)
in
  r
end 

implement bitcoinrpc_json (base, url, auth, json) = let
  val s = json_dumps (json, 0)
  val () = assertloc (strptr_isnot_null s)
in
  bitcoinrpc_strptr (base, url, auth, s)
end 

implement bitcoinrpc_cn_fun (cn, url, auth, json, cb) = {
  fun handle_cn_rpc (client: !evhttp_request1, cb: rpc_callback):void = let
    val code = if evhttp_request_isnot_null (client) then evhttp_request_get_response_code(client) else 501
  in
    if code = HTTP_OK then {
      val result = get_request_input_string (client)
      var e: json_error_t? 
      val json = json_loads(castvwtp1 {string} (result), 0, e);
      val () = cb ((if ~json then rpc_result_json json else rpc_result_error json): rpc_result1)
      val () = cloptr_free (cb)
      val () = strptr_free (result)
    }
    else {
      val () = cb (rpc_result_http_error (code))
      val () = cloptr_free (cb)
    }
  end

  val uri = evhttp_uri_parse (url)
  val () = assertloc (~uri)

  val (pff_host | host) = evhttp_uri_get_host (uri)
  val () = assertloc (strptr_isnot_null (host))

  val (pff_path | path) = evhttp_uri_get_path (uri)
  val () = assertloc (strptr_isnot_null (path))

  (* Copy a reference to the connection so we can pass it to the callback when the request is made *)
  val client = evhttp_request_new {rpc_callback} (handle_cn_rpc, cb) 
  val () = assertloc (~client)

  val (pff_headers | headers) = evhttp_request_get_output_headers(client)
  val r = evhttp_add_header(headers, "Host", castvwtp1 {string} (host))
  val () = assertloc (r = 0)

  val r = evhttp_add_header(headers, "Content-Type", "application/json")
  val () = assertloc (r = 0)

  val auth = string_to_base64 (auth)
  val () = assertloc (strptr_isnot_null (auth))
  val auth1 = string1_of_string (castvwtp1 {string} (auth))
  val authorization = string1_append ("Basic ", auth1)
  val authorization = strptr_of_strbuf authorization
  val r = evhttp_add_header(headers, "Authorization", castvwtp1 {string} (authorization))
  val () = assertloc (r = 0)
  val () = strptr_free (authorization)
  val () = strptr_free (auth)

  val (pff_buffer | buffer) = evhttp_request_get_output_buffer (client)
  val s = string1_of_string (json)
  val r = evbuffer_add_string (buffer, s, string1_length (s))
  val () = assertloc (r = 0)
  prval () = pff_buffer (buffer)

  val r = evhttp_make_request(cn, client, EVHTTP_REQ_POST, castvwtp1 {string} (path))
  val () = assertloc (r = 0)

  prval () = pff_path (path)
  prval () = pff_host (host)
  prval () = pff_headers (headers)
  val () = evhttp_uri_free (uri)
}

implement bitcoinrpc_cn_string (cn, url, auth, json) = let
  val tsk = global_scheduler_halt ()
  var result: rpc_result1
  prval (pff, pf) = __borrow (view@ result) where {
                      extern prfun __borrow {l:addr} (r: !rpc_result1? @ l >> (rpc_result1 @ l))
                                      : (rpc_result1 @ l -<lin,prf> void, rpc_result1? @ l)
                    }
  val () = bitcoinrpc_cn_fun (cn, url, auth, json, llam (r) => {
                                val () = global_scheduler_queue_task (tsk)
                                val () = result := r
                                prval () = pff (pf)
                              })
  val () = global_scheduler_resume ()
in
  result
end

implement bitcoinrpc_connect (base, url) = let
  val uri = evhttp_uri_parse (url)
  val () = assertloc (~uri)

  val (pff_host | host) = evhttp_uri_get_host (uri)
  val () = assertloc (strptr_isnot_null (host))

  val port = evhttp_uri_get_port (uri)
  val () = assertloc (port >= 80)
  val port = uint16_of_int port

  val cn = evhttp_connection_base_new(base,
                                      null,
                                      castvwtp1 {string} (host),
                                      port)
  prval () = pff_host (host)
  val () = evhttp_uri_free (uri)
in
  cn
end

implement bitcoinrpc_disconnect (conn) = evhttp_connection_free (conn)

