staload "bitcoin/SATS/rpc.sats"
staload "libevent/SATS/libevent.sats"
staload "jansson/SATS/jansson.sats"
staload "task/SATS/task.sats"
dynload "task/DATS/task.dats"

fun event_loop_task {l:agz} (pff: event_base l -<lin,prf> void | base: event_base l, events_queued: bool): void = let
  val () = task_yield ()
in
  (* If no events are queued and if no tasks are also queued we can exit *)
  if event_base_got_exit (base) > 0 || (not events_queued && task_queue_count () + task_paused_count () = 0) then {
    prval () = pff (base)
  }

  (* We're the only active task left, safe to block *)
  else if task_queue_count () = 0 then event_loop_task (pff | base, event_base_loop (base, EVLOOP_ONCE) = 0)

  (* Other tasks are waiting, we can't block *)
  else event_loop_task (pff | base, event_base_loop (base, EVLOOP_NONBLOCK) = 0)
end

fn do_main {l:agz} (pff: event_base l -<lin,prf> void | base: event_base l, uri: string, auth: string): void = {
  fn print_result (r: rpc_result1): void =
    case+ r of 
    | ~rpc_result_json json => {
                                 val s = json_dumps (json, 0)
                                 val () = assertloc (strptr_isnot_null s)
                                 val () = print s
                                 val () = print_newline ()
                                 val () = strptr_free (s)
                                 val () = json_decref (json)
                               }
    | ~rpc_result_error json => {
                                 val () = printf ("JSON error\n", @())
                                 val () = json_decref (json)
                               }
    | ~rpc_result_http_error code => printf("Http Error: %d\n", @(code)) 

  val cn = bitcoinrpc_connect (base, uri)
  val () = assertloc (~cn)

  val r1 = print_result(bitcoinrpc (cn, uri, auth, "{\"method\":\"getdifficulty\",\"params\":[],\"id\":0}"))
  val r2 = print_result(bitcoinrpc (cn, uri, auth, "{\"method\":\"getblockcount\",\"params\":[],\"id\":0}"))
  val () = bitcoinrpc_disconnect (cn)
  prval ( )= pff base
}

implement main (argc, argv) = {
  (* Usage: ./foo http://127.0.0.1:8332/ un:pw *)
  val () = assertloc (argc = 3)

  var sch = scheduler_new ()
  val () = set_global_scheduler (sch)

  val base = event_base_new ()
  val () = assertloc (~base)

  extern castfn __ref {l:agz} (base: !event_base l): (event_base l -<lin,prf> void | event_base l)
  val (pff_base1 | base1) = __ref (base)
  val (pff_base2 | base2) = __ref (base)

  val url = argv.[1]
  val auth = argv.[2]
  val () = task_spawn_lin (16384, llam () => do_main (pff_base1 | base1, url, auth));
  val () = task_spawn_lin (16384, llam () => event_loop_task (pff_base2 | base2, true))

  val () = run_global_scheduler ()

  val () = event_base_free (base)

  val () = unset_global_scheduler (sch)
  val () = scheduler_free (sch)
}

