(macro generate-operators! [Class fields]
  (var out [])
  (local math-ops
         [[:__unm `#(- $1) false]
          [:__pow `^ false]
          [:__mod `% false]
          [:__add `+ true]
          [:__sub `- true]
          [:__mul `* true]
          [:__div `/ true]])

  ;; generate math operations
  (each [i# [op-name op variadic] (ipairs math-ops)]
    (table.insert
     out
     `(tset (. ,Class :mt) ,op-name
       (fn [...]
         ;; Turn all args into vectors, if possible
         (let [vals# (icollect [_# arg# (ipairs [...])]
                       (if (= (type arg#) :table) arg# (,Class arg#)))]
           ;; Check if more than 2 operands for variadic ops (less common)
           (if (. vals# 3)
            ;; loop to apply operation
            (faccumulate [acc# (. vals# 1) i# 2 (length vals#)]
              (,Class
                ,(unpack (icollect [_ field (ipairs fields)]
                          ;; perform operation on 2 items at a time
                          `(,op (. acc# ,field) (. (. vals# i#) ,field))))))
            ;; Just apply operation on 2 operands (no loop)
            (let [[a# b#] vals#]
              (,Class
                ,(unpack (icollect [_ field (ipairs fields)]
                           `(,op (. a# ,field) (. b# ,field))))))))))))

  ;; generate compare operations
  (table.insert
   out
   `(tset (. ,Class :mt) :__eq
      (fn [self# other#]
        (and
         ,(unpack (icollect [_i field (ipairs fields)]
                   `(= (. self# ,field) (. other# ,field))))))))

  ;; (table.insert
  ;;  out
  ;;  `(tset ,Class :map
  ;;    (fn [self f ...]
  ;;      ()

  ;;     (let [index-list (fn [l index] (icollect [_i v (ipairs l)] (. v index)))]
  ;;          as-vec (fn [t] (if (= (type t) :table) t (Class t)))
  ;;           self (as-vec self)
  ;;           rest (icollect [_i v (ipairs [...])] (as-vec v))
  ;;       (Class (unpack (icollect [_i v (ipairs fields)]
  ;;                       (f (. self v) (unpack (index-list rest v))))))))))

  `(do (unpack ,out)))


(fn generate-operators [Class fields]
  ;;
  (fn Class.map [self f ...]
      (let [index-list (fn [l index] (icollect [_i v (ipairs l)] (. v index)))
            as-vec (fn [t] (if (= (type t) :table) t (Class t)))
            self (as-vec self)
            rest (icollect [_i v (ipairs [...])] (as-vec v))]
        (Class (unpack (icollect [_i v (ipairs fields)]
                        (f (. self v) (unpack (index-list rest v)))))))))

(var Vec2 (util.class))
(fn Vec2.constructor [x y] {: x :y (if y y x)})
(generate-operators Vec2 [:x :y])
(generate-operators! Vec2 [:x :y])
(fn Vec2.within-rectangle [self pos size]
  (and
   (> self.x pos.x) (< self.x (+ pos.x size.x))
   (> self.y pos.y) (< self.y (+ pos.y size.y))))

;; intersect a ray from the screen with a plane where x=x
(fn Vec2.intersect-xy-plane [{:x screen-x :y screen-y} z]
  (_G.Vec3 (+ z (/ screen-x 16))
           (+ (/ screen-x -32) (/ screen-y 16) (- z))
           z))

;; intersect a ray from the screen with a plane where x=x
(fn Vec2.intersect-yz-plane [{:x screen-x :y screen-y} x]
  (_G.Vec3 x
           (+ (/ screen-x 32) (/ screen-y 16) (- x))
           (- x (/ screen-x 16))))

;; intersect a ray from the screen with a plane with z=z
(fn Vec2.intersect-xz-plane [{:x screen-x :y screen-y} y]
  (_G.Vec3 (+ (/ screen-y 16) (/ screen-x 32) (- y))
           y
           (+ (/ screen-y 16) (/ screen-x -32) (- y))))

(var Vec3 (util.class))
(fn Vec3.constructor [x y z] {: x :y (if y y x) :z (if z z x)})
(generate-operators Vec3 [:x :y :z])
(generate-operators! Vec3 [:x :y :z])
(fn Vec3.project-to-screen [{: x : y : z}]
  (Vec2 (* 16 (- x z))
        (* 16 (+ y (/ (+ x z) 2)))))
(fn Vec3.within [self pos size]
  (and
   (>= self.x pos.x) (< self.x (+ pos.x size.x))
   (>= self.y pos.y) (< self.y (+ pos.y size.y))
   (>= self.z pos.z) (< self.z (+ pos.z size.z))))

(set _G.Vec2 Vec2)
(set _G.Vec3 Vec3)

;; DEBUG ;;;;;;
;; (local {: pp : Vec2 : Vec3} _G)
;; (_G.pp (_G.Vec3 5 10 15))
;; (_G.pp (- (_G.Vec3 5 10 15)))
;; (_G.pp (* (_G.Vec3 2 2 2) (_G.Vec3 5 10 15)))
;; (_G.pp (+ (_G.Vec2 0 0) (_G.Vec2 5 5)))
;; (_G.pp (+ (_G.Vec2 0 0)))
;; (_G.pp (+ (_G.Vec2 0 0) 5))
;; (_G.pp (= (_G.Vec3 1 1 1) (_G.Vec3 1 1 1)))
;; (_G.pp (= (_G.Vec3 1 1 1) (_G.Vec3 2 1 1)))
;; (_G.pp (= (_G.Vec3 1 1 1) (_G.Vec3 1 2 1)))
;; (_G.pp (= (_G.Vec3 1 1 1) (_G.Vec3 1 1 2)))
;; (pp (Vec3.within (Vec3 0.5 0.5 0.5) (Vec3 0 0 0) (Vec3 1 1 1)))
;; (pp (Vec3.within (Vec3 0 0 0) (Vec3 0 0 0) (Vec3 1 1 1)))
;; (pp (Vec3.within (Vec3 1 1 1) (Vec3 0 0 0) (Vec3 1 1 1)))
