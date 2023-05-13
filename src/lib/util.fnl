(set _G.util {})

;; Convert tile coordinates to screen coordinates
(fn _G.util.iso-to-screen [x y z]
  (values (* 16 (- z x))
          (* 16 (+ y (/ (+ x z) 2)))))

;; Create a table which is a class X. When called as (X ...), it will construct
;; an object Y by calling X.constructor(...). The optional method
;; X.instantiate(...) will be called afterwards if it exists, for extra work
;; that requires methods to be bound.
(fn _G.util.class [class]
  (let [class (if class class {})]
    (set class.mt {:__index class})
    (setmetatable class {:__call
                         (fn [_class ...]
                           (let [instance (setmetatable (class.constructor ...) class.mt)]
                            (when class.instantiate (instance:instantiate ...))
                            instance))})))

(fn _G.util.clamp [v lower upper]
  (math.min upper (math.max lower v)))
