staload "bitcoin/SATS/base64.sats"
staload "prelude/SATS/unsafe.sats"

#define ATS_DYNLOADFLAG 0 // no need for dynloading at run-time

%{^
#include "bitcoin/CATS/modp_b64.h"
#include "bitcoin/CATS/modp_b64.c"
%}

dataview encode_v (int, int, addr) =
  | {l:agz} {bsz:nat} {rlen:int | rlen > 0; rlen <= bsz }
      encode_v_succ (bsz, rlen, l) of strbuf (bsz, rlen - 1) @ l 
  | {l:agz} {bsz:nat} {rlen:int | rlen <= 0 } 
      encode_v_fail (bsz, rlen, l) of b0ytes bsz @ l

extern fun modp_b64_encode 
             {l:agz}
             {n,bsz:nat | bsz >= (n + 2) / 3 * 4 + 1}
             (pf_dest: !b0ytes bsz @ l >> encode_v (bsz, rlen, l) |  
              dest: ptr l,
              str: string n, 
              len: sizeLte n
             ): #[rlen:int | rlen <= bsz] size_t rlen 
             = "mac#modp_b64_encode"


implement string_to_base64 (s) = let
  val s = string1_of_string s
  val s_len = string1_length (s)
  val d_len = (s_len + 2) / 3 * 4 + 1
  val (pfgc, pf_bytes | p_bytes) = malloc_gc d_len
  val len = modp_b64_encode (pf_bytes | p_bytes, s, s_len) 
in
  if len > 0 then let
      prval encode_v_succ pf = pf_bytes                    
    in
      strptr_of_strbuf @(pfgc, pf | p_bytes)
    end
  else let  
      prval encode_v_fail pf = pf_bytes                   
      val () = free_gc (pfgc, pf | p_bytes)
    in
      strptr_null ()
    end
end
