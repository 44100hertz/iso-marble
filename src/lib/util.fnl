(local util {})

(set util.lume (require :lib.lume))

;; Create a table which is a class X. When called as (X ...), it will construct
;; an object Y by calling X.constructor(...). The optional method
;; X.instantiate(...) will be called afterwards if it exists, for extra work
;; that requires methods to be bound.
(fn util.class [class]
  (let [class (if class class {})]
    (set class.mt {:__index class})
    (setmetatable
     class
     {:__call (fn [_class ...]
                (let [instance (setmetatable (class.constructor ...) class.mt)]
                 (when class.instantiate (instance:instantiate ...))
                 instance))})))

(set util.clamp util.lume.clamp)

(fn util.with-scroll [args f]
  (util.with-transform-list [:translate (unpack args)] f))

;; pass in a list of graphical transforms to apply when calling f
;; for example:
;; (util.with-transform-list [[:translate 10 20]] #(draw-carrot 100))
(fn util.with-transform-list [tforms f]
  (util.with-transform (util.transform-from tforms) f))

;; pass in a transform object and it will apply the transform when calling a
;; function
(fn util.with-transform [tform f]
  (love.graphics.push)
  (love.graphics.applyTransform tform)
  (f)
  (love.graphics.pop))

;; pass in a list of graphical transforms to convert into a transform object
;; for example:
;; (util.transform-from-list [[:translate 10 20]])
(fn util.transform-from-list [...]
  (let [out (love.math.newTransform)]
    (each [_i [tform a b c d] (ipairs [...])]
      ((. out tform) out
       (if (= (type a) :table) (values a.x a.y)
           (values a b c d))))
    out))

(fn util.with-color-rgba [r g b a f]
  (let [(oldr oldg oldb olda) (love.graphics.getColor)]
    (love.graphics.setColor r g b a)
    (f)
    (love.graphics.setColor oldr oldg oldb olda)))

(fn util.screen-size [] (_G.Vec2 (love.window.getMode)))

;; take any number of tables and combine them
(set util.union util.lume.merge)

(set _G.util util)
