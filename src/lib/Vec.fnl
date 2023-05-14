(local operators
       {:__unm #(- 0 $1)
        :__add #(+ $1 $2)
        :__sub #(- $1 $2)
        :__mul #(* $1 $2)
        :__div #(/ $1 $2)
        :__mod #(% $1 $2)})

;; given a list and index, return a new list which indexes each entry by index
(fn index-list [l index] (icollect [_i v (ipairs l)] (. l index)))

;; Given a class and a list of fields, generate operations for the class. For
;; example, given fields [:x :y] operation (+ p1 p2) will be the same as (Vec2
;; (+ p1.x p2.x) (+ p1.y p2.y))
(fn generate-operators [Class fields]
  ;; take up to 2 things
  (set Class.map
        (fn [self f other]
          (Class (unpack (icollect [_i v (ipairs fields)]
                          (f (. self v) (if other (. other v))))))))
  (each [k v (pairs operators)]
    (tset Class.mt k #(Class.map $1 v $2))))

(var Vec2 (util.class))
(fn Vec2.constructor [x y] {: x :y (if y y x)})
(generate-operators Vec2 [:x :y])

(var Vec3 (util.class))
(fn Vec3.constructor [x y z] {: x :y (if y y x) :z (if z z x)})
(generate-operators Vec3 [:x :y :z])

(set _G.Vec2 Vec2)
(set _G.Vec3 Vec3)

;; DEBUG ;;;;;;
(_G.pp (_G.Vec3 5 10 15))
(_G.pp (- (_G.Vec3 5 10 15)))
(_G.pp (* (_G.Vec3 2 2 2) (_G.Vec3 5 10 15)))
