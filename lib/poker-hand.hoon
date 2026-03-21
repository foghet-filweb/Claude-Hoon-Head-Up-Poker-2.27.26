::  /app/poker-hand.hoon
::
::  Poker hand evaluator for Fhloston Poker.
::  Determines the best 5-card hand from a set of cards,
::  ranks hands, and compares two hands to find the winner.
::
::  Supports:
::    Hold'em   (2 hole + up to 5 community → best 5 of 7)
::    Omaha     (exactly 2 of 4 hole + exactly 3 of 5 community)
::    5-Card Draw (best 5 of 5)
::
::  Card representation:
::    Cards are atoms (primes) as defined in app/poker-sra.hoon.
::    Before evaluation they are decoded to [suit=@ud rank=@ud]
::    where suit ∈ [0,3] and rank ∈ [0,12] (0=2 … 12=A).
::
::  Hand ranking (ascending):
::    0  high-card
::    1  one-pair
::    2  two-pair
::    3  three-of-a-kind
::    4  straight
::    5  flush
::    6  full-house
::    7  four-of-a-kind
::    8  straight-flush
::    9  royal-flush  (ace-high straight-flush)
::
::  Comparison:
::    ++best-hand returns a [hand-rank (list @ud)] where the list
::    is the kicker sequence (high to low) used as a tiebreaker.
::    ++compare-hands returns ?(%alice %bob %tie).
::
|%
::  +$ card: decoded card with suit and rank
+$  card  [suit=@ud rank=@ud]

::  +$ hand-rank: numeric hand category
::    0 high-card  1 pair  2 two-pair  3 trips  4 straight
::    5 flush  6 full-house  7 quads  8 str-flush  9 royal-flush
+$  hand-rank  @ud

::  +$ eval-result: hand category + ordered kicker list for tiebreaking
+$  eval-result  [rank=hand-rank kickers=(list @ud)]

::  +$ winner: result of a showdown comparison
+$  winner  ?(%alice %bob %tie)

::  ────────────────────────────────────────────────────────────
::  Public API
::  ────────────────────────────────────────────────────────────

::  ++eval-holdem: best 5-card hand from 2 hole cards + up to 5 community
::  Tries all C(7,5)=21 combinations and returns the highest.
++  eval-holdem
  |=  [hole=(list @ud) community=(list @ud)]
  ^-  eval-result
  ?>  =((lent hole) 2)
  ?>  (lte (lent community) 5)
  =/  all     (weld hole community)
  =/  combos  (combinations-5 all)
  (best-of combos)

::  ++eval-omaha: best hand using EXACTLY 2 of 4 hole + EXACTLY 3 of 5 community
++  eval-omaha
  |=  [hole=(list @ud) community=(list @ud)]
  ^-  eval-result
  ?>  =((lent hole) 4)
  ?>  =((lent community) 5)
  =/  hole-pairs    (combinations-k hole 2)
  =/  comm-triples  (combinations-k community 3)
  =/  all-combos=(list (list @ud))
    %+  skim
      %+  turn
        %+  roll  hole-pairs
        |=  [hp=(list @ud) acc=(list (list @ud))]
        %+  weld  acc
        %+  turn  comm-triples
        |=(ct=(list @ud) (weld hp ct))
      same
    |=(hand=(list @ud) =((lent hand) 5))
  (best-of all-combos)

::  ++eval-5cd: evaluate exactly 5 cards (5-card draw)
++  eval-5cd
  |=  cards=(list @ud)
  ^-  eval-result
  ?>  =((lent cards) 5)
  (eval-5 cards)

::  ++compare-hands: determine showdown winner
::  Returns %alice, %bob, or %tie
++  compare-hands
  |=  [alice=eval-result bob=eval-result]
  ^-  winner
  ?:  (gth rank.alice rank.bob)  %alice
  ?:  (lth rank.alice rank.bob)  %bob
  (compare-kickers kickers.alice kickers.bob)

::  ++holdem-winner: convenience gate combining eval + compare
++  holdem-winner
  |=  $:  alice-hole=(list @ud)
          bob-hole=(list @ud)
          community=(list @ud)
      ==
  ^-  winner
  =/  alice-result  (eval-holdem alice-hole community)
  =/  bob-result    (eval-holdem bob-hole community)
  (compare-hands alice-result bob-result)

::  ────────────────────────────────────────────────────────────
::  Core 5-card evaluator
::  ────────────────────────────────────────────────────────────

::  ++eval-5: evaluate exactly 5 card primes
++  eval-5
  |=  primes=(list @ud)
  ^-  eval-result
  ?>  =((lent primes) 5)
  =/  cards        (turn primes decode-card)
  =/  ranks        (sort (turn cards |=(c=card rank.c)) gth)
  =/  suits        (turn cards |=(c=card suit.c))
  =/  is-flush     (flush-check suits)
  =/  is-straight  (straight-check ranks)
  =/  rank-counts  (count-ranks ranks)
  ?:  &(is-flush is-straight)
    ?:  =((snag 0 ranks) 12)
      [9 ranks]
    [8 ranks]
  ?:  (has-n-of-a-kind rank-counts 4)
    [7 (kickers-quads rank-counts ranks)]
  ?:  (is-full-house rank-counts)
    [6 (kickers-full-house rank-counts)]
  ?:  is-flush
    [5 ranks]
  ?:  is-straight
    [4 (straight-kickers ranks)]
  ?:  (has-n-of-a-kind rank-counts 3)
    [3 (kickers-trips rank-counts ranks)]
  ?:  (is-two-pair rank-counts)
    [2 (kickers-two-pair rank-counts ranks)]
  ?:  (has-n-of-a-kind rank-counts 2)
    [1 (kickers-pair rank-counts ranks)]
  [0 ranks]

::  ────────────────────────────────────────────────────────────
::  Classification helpers
::  ────────────────────────────────────────────────────────────

::  ++flush-check: all 5 cards share the same suit
++  flush-check
  |=  suits=(list @ud)
  ^-  ?
  ?~  suits  %.y
  =/  first  i.suits
  (levy t.suits |=(s=@ud =(s first)))

::  ++straight-check: ranks form a consecutive sequence
::  Handles the wheel (A-2-3-4-5) where ace plays low.
++  straight-check
  |=  ranks=(list @ud)
  ^-  ?
  =/  normal
    ?&  =((sub (snag 0 ranks) (snag 4 ranks)) 4)
        =((lent (dedupe ranks)) 5)
    ==
  =/  wheel
    =((sort ranks lth) ~[0 1 2 3 12])
  |(normal wheel)

::  ++straight-kickers: for a straight, kicker is the high card
::  Wheel (A-2-3-4-5) gets a high card of 3 (5-high straight)
++  straight-kickers
  |=  ranks=(list @ud)
  ^-  (list @ud)
  =/  sorted  (sort ranks lth)
  ?:  =(sorted ~[0 1 2 3 12])
    ~[3]
  ~[(snag 0 (sort ranks gth))]

::  ++count-ranks: produce a map of rank → count
++  count-ranks
  |=  ranks=(list @ud)
  ^-  (map @ud @ud)
  =|  counts=(map @ud @ud)
  |-
  ?~  ranks  counts
  =/  r    i.ranks
  =/  cur  (~(gut by counts) r 0)
  $(ranks t.ranks, counts (~(put by counts) r +(cur)))

::  ++has-n-of-a-kind: true if any rank appears exactly n times
++  has-n-of-a-kind
  |=  [counts=(map @ud @ud) n=@ud]
  ^-  ?
  %+  lien  ~(val by counts)
  |=(c=@ud =(c n))

::  ++is-full-house: three of one rank + two of another
++  is-full-house
  |=  counts=(map @ud @ud)
  ^-  ?
  &((has-n-of-a-kind counts 3) (has-n-of-a-kind counts 2))

::  ++is-two-pair: two different ranks each appear twice
++  is-two-pair
  |=  counts=(map @ud @ud)
  ^-  ?
  =/  pairs  (skim ~(val by counts) |=(c=@ud =(c 2)))
  =((lent pairs) 2)

::  ────────────────────────────────────────────────────────────
::  Kicker builders
::  Kicker lists are ordered so that lexicographic comparison
::  produces the correct tiebreaker result.
::  ────────────────────────────────────────────────────────────

::  ++kickers-quads: [quad-rank kicker]
++  kickers-quads
  |=  [counts=(map @ud @ud) ranks=(list @ud)]
  ^-  (list @ud)
  =/  quad    (need (find-rank-with-count counts 4))
  =/  kicker  (need (find-rank-with-count counts 1))
  ~[quad kicker]

::  ++kickers-full-house: [trips-rank pair-rank]
++  kickers-full-house
  |=  counts=(map @ud @ud)
  ^-  (list @ud)
  =/  trips  (need (find-rank-with-count counts 3))
  =/  pair   (need (find-rank-with-count counts 2))
  ~[trips pair]

::  ++kickers-trips: [trips-rank high-kicker low-kicker]
++  kickers-trips
  |=  [counts=(map @ud @ud) ranks=(list @ud)]
  ^-  (list @ud)
  =/  trips   (need (find-rank-with-count counts 3))
  =/  rest    (skim ranks |=(r=@ud !=(r trips)))
  =/  sorted  (sort rest gth)
  (weld ~[trips] sorted)

::  ++kickers-two-pair: [high-pair low-pair kicker]
++  kickers-two-pair
  |=  [counts=(map @ud @ud) ranks=(list @ud)]
  ^-  (list @ud)
  =/  pairs   (sort (skim ~(tap in ~(key by counts)) |=(r=@ud =((~(got by counts) r) 2))) gth)
  =/  high    (snag 0 pairs)
  =/  low     (snag 1 pairs)
  =/  kicker  (need (find-rank-with-count counts 1))
  ~[high low kicker]

::  ++kickers-pair: [pair-rank k1 k2 k3]
++  kickers-pair
  |=  [counts=(map @ud @ud) ranks=(list @ud)]
  ^-  (list @ud)
  =/  pair  (need (find-rank-with-count counts 2))
  =/  rest  (sort (skim ranks |=(r=@ud !=(r pair))) gth)
  (weld ~[pair] rest)

::  ++find-rank-with-count: find highest rank that appears exactly n times
++  find-rank-with-count
  |=  [counts=(map @ud @ud) n=@ud]
  ^-  (unit @ud)
  =/  matching  (skim ~(tap in ~(key by counts)) |=(r=@ud =((~(got by counts) r) n)))
  ?~  matching  ~
  `(snag 0 (sort matching gth))

::  ────────────────────────────────────────────────────────────
::  Tiebreaker comparison
::  ────────────────────────────────────────────────────────────

++  compare-kickers
  |=  [a=(list @ud) b=(list @ud)]
  ^-  winner
  ?~  a  %tie
  ?~  b  %tie
  ?:  (gth i.a i.b)  %alice
  ?:  (lth i.a i.b)  %bob
  $(a t.a, b t.b)

::  ────────────────────────────────────────────────────────────
::  Combination generators
::  ────────────────────────────────────────────────────────────

::  ++combinations-5: all C(n,5) 5-card combinations from a list
++  combinations-5
  |=  cards=(list @ud)
  ^-  (list (list @ud))
  (combinations-k cards 5)

::  ++combinations-k: all C(n,k) k-element subsets of a list
++  combinations-k
  |=  [lst=(list @ud) k=@ud]
  ^-  (list (list @ud))
  ?:  =(k 0)  ~[~]
  ?~  lst     ~
  =/  with
    %+  turn
      (combinations-k t.lst (sub k 1))
    |=(sub=(list @ud) [i.lst sub])
  =/  without  (combinations-k t.lst k)
  (weld with without)

::  ++best-of: evaluate all 5-card combos and return the highest
++  best-of
  |=  combos=(list (list @ud))
  ^-  eval-result
  ?~  combos  [0 ~]
  =/  first  (eval-5 i.combos)
  |-
  ?~  t.combos  first
  =/  next  (eval-5 i.t.combos)
  =/  better
    ?-  (compare-hands first next)
      %alice  first
      %bob    next
      %tie    first
    ==
  $(t.combos t.t.combos, first better)

::  ────────────────────────────────────────────────────────────
::  Card decode
::  ────────────────────────────────────────────────────────────

::  ++decode-card: convert a card prime to [suit rank]
::  The 52 card primes map to indices 0..51;
::  suit = index / 13, rank = index mod 13.
++  decode-card
  |=  prime=@ud
  ^-  card
  =/  deck  card-primes
  =/  idx   (find-prime prime deck 0)
  [(div idx 13) (mod idx 13)]

::  ++find-prime: linear search for prime in deck, returns index
++  find-prime
  |=  [target=@ud deck=(list @ud) idx=@ud]
  ^-  @ud
  ?~  deck
    ~|('decode-card: unknown card prime' !!)
  ?:  =(i.deck target)  idx
  $(deck t.deck, idx +(idx))

::  ++card-primes: canonical ordered list of 52 card primes
::  Must match app/poker-sra.hoon ++make-deck exactly.
++  card-primes
  ^~
  ^-  (list @ud)
  ~[53 59 61 67 71 73 79 83 89 97 101 103 107 109 113 127 131 137 139 149 151 157 163 167 173 179 181 191 193 197 199 211 223 227 229 233 239 241 251 257 263 269 271 277 281 283 293 307 311 313 317 331]

::  ────────────────────────────────────────────────────────────
::  Display helpers (debugging / UI)
::  ────────────────────────────────────────────────────────────

::  ++rank-name: human-readable rank
++  rank-name
  |=  rank=@ud
  ^-  cord
  ?+  rank  'unknown'
    %0   '2'   %1   '3'   %2   '4'   %3   '5'
    %4   '6'   %5   '7'   %6   '8'   %7   '9'
    %8   'T'   %9   'J'   %10  'Q'   %11  'K'   %12  'A'
  ==

::  ++suit-name: human-readable suit
++  suit-name
  |=  suit=@ud
  ^-  cord
  ?+  suit  'unknown'
    %0  'c'   %1  'd'   %2  'h'   %3  's'
  ==

::  ++hand-name: human-readable hand category
++  hand-name
  |=  rank=hand-rank
  ^-  cord
  ?+  rank  'unknown'
    %0  'High Card'        %1  'One Pair'          %2  'Two Pair'
    %3  'Three of a Kind'  %4  'Straight'          %5  'Flush'
    %6  'Full House'       %7  'Four of a Kind'    %8  'Straight Flush'
    %9  'Royal Flush'
  ==

::  ────────────────────────────────────────────────────────────
::  Utility
::  ────────────────────────────────────────────────────────────

::  ++dedupe: remove duplicate elements from a list, preserving order
++  dedupe
  |=  lst=(list @ud)
  ^-  (list @ud)
  =|  seen=(set @ud)
  =|  acc=(list @ud)
  |-
  ?~  lst  (flop acc)
  ?:  (~(has in seen) i.lst)
    $(lst t.lst)
  %=  $
    lst   t.lst
    seen  (~(put in seen) i.lst)
    acc   [i.lst acc]
  ==
--
