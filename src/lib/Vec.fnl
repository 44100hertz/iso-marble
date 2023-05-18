;; workaround to make operators variadic because #(+ $...) doesn't work
;; https://todo.sr.ht/~technomancy/fennel/170
(fn variadic-operator [op]
  (fn [start ...] (accumulate [acc start _i n (ipairs [...])]
                    (op acc n))))

(local operators
       {:__unm #(- $1)
        :__mod #(% $1 $2)
        :__add (variadic-operator #(+ $1 $2))
        :__sub (variadic-operator #(- $1 $2))
        :__mul (variadic-operator #(* $1 $2))
        :__div (variadic-operator #(/ $1 $2))})

;; given a list and index, return a new list which indexes each entry by index

;; Given a class and a list of fields, generate operations for the class. For
;; example, given fields [:x :y] operation (+ p1 p2) will be the same as (Vec2
;; (+ p1.x p2.x) (+ p1.y p2.y))
(fn generate-operators [Class fields]
  ;; take up to 8 points and does an operation on the fields of those points,
  ;; for example:
  ;; (Vec2.map (Vec2 1 2) (Vec2 3 4) #(+ $1 $2))
  ;; is the same as (Vec2 (+ 1 3) (+ 2 4))
  (set Class.map
       (fn [self f ...]
         (let [index-list (fn [l index] (icollect [_i v (ipairs l)] (. v index)))
               as-class (fn [t] (if (= (type t) :table) t (Class t)))
               self (as-class self)
               rest (icollect [_i v (ipairs [...])] (as-class v))]
           (Class (unpack (icollect [_i v (ipairs fields)]
                           (f (. self v) (unpack (index-list rest v)))))))))
  (each [k v (pairs operators)]
    (tset Class.mt k #(Class.map $1 v $2))))

(var Vec2 (util.class))
(fn Vec2.constructor [x y] {: x :y (if y y x)})
(generate-operators Vec2 [:x :y])
(fn Vec2.within-rectangle [self pos size]
  (and
   (> self.x pos.x) (< self.x (+ pos.x size.x))
   (> self.y pos.y) (< self.y (+ pos.y size.y))))
(fn Vec2.project-from-screen [{:x screen-x :y screen-y} y]
  (_G.Vec3 (+ (/ screen-y 16) (/ screen-x 32) y)
           y
           (+ (/ screen-y 16) (/ screen-x -32) y)))

(var Vec3 (util.class))
(fn Vec3.constructor [x y z] {: x :y (if y y x) :z (if z z x)})
(generate-operators Vec3 [:x :y :z])
(fn Vec3.project-to-screen [{: x : y : z}]
  (Vec2 (* 16 (- x z))
        (* 16 (+ y (/ (+ x z) 2)))))

(set _G.Vec2 Vec2)
(set _G.Vec3 Vec3)

;; DEBUG ;;;;;;
;; (_G.pp (_G.Vec3 5 10 15))
;; (_G.pp (- (_G.Vec3 5 10 15)))
;; (_G.pp (* (_G.Vec3 2 2 2) (_G.Vec3 5 10 15)))
;; (_G.pp (+ (_G.Vec2 0 0) 5))
;; (_G.pp (type (Vec2 0)))
