(*
** Copyright (C) 2012 Chris Double.
**
** Permission to use, copy, modify, and distribute this software for any
** purpose with or without fee is hereby granted, provided that the above
** copyright notice and this permission notice appear in all copies.
** 
** THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
** WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
** MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
** ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
** WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
** ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
** OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
*)
#define ATS_STALOADFLAG 0 // no need for staloading at run-time

staload "contrib/libevent/SATS/libevent.sats"
staload "contrib/jansson/SATS/jansson.sats"

dataviewtype rpc_result (l:addr) =
  | rpc_result_json (l) of ([l > null] JSONptr (l, 0))
  | rpc_result_error (l) of ([l <= null] JSONptr (l, 0))
  | rpc_result_http_error (null) of (int)

viewtypedef rpc_result1 = [l:addr] rpc_result l
viewtypedef rpc_callback = (rpc_result1) -<lincloptr1> void

fun bitcoinrpc_fun {l:agz} (base: !event_base l, url: string, auth: string, json: string, cb: rpc_callback): void
symintr bitcoinrpc
fun bitcoinrpc_string {l:agz} (base: !event_base l, url: string, auth: string, json: string): rpc_result1
fun bitcoinrpc_strptr {l:agz} (base: !event_base l, url: string, auth: string, json: strptr1): rpc_result1
fun bitcoinrpc_json {l,l2:agz} (base: !event_base l, url: string, auth: string, json: !JSONptr (l2, 0)): rpc_result1
overload bitcoinrpc with bitcoinrpc_string
overload bitcoinrpc with bitcoinrpc_strptr
overload bitcoinrpc with bitcoinrpc_json

fun bitcoinrpc_cn_fun {l:agz} (cn: !evhttp_connection l, url: string, auth: string, json: string, cb: rpc_callback): void
fun bitcoinrpc_cn_string {l:agz} (cn: !evhttp_connection l, url: string, auth: string, json: string): rpc_result1

overload bitcoinrpc with bitcoinrpc_cn_fun
overload bitcoinrpc with bitcoinrpc_cn_string

fun bitcoinrpc_connect {l:agz} (base: !event_base l, url: string): [l2:addr] evhttp_connection l2
fun bitcoinrpc_disconnect {l:agz} (conn: evhttp_connection l): void

