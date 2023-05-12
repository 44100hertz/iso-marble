(set _G.util {})

;; Convert tile coordinates to screen coordinates
(fn _G.util.iso-to-screen [x y z]
  (values (* 16 (- z x))
          (* 16 (+ y (/ (+ x z) 2)))))

;; Create a table which is a class X. When called as (X ...), it will construct
;; an object Y by calling X.constructor(...).
(fn _G.util.class [class]
  (let [class (if class class {})]
    (set class.mt {:__index class})
    (setmetatable class {:__call
                         (fn [_class ...]
                           (setmetatable (class.constructor ...) class.mt))})
    class))

(fn _G.util.clamp [v lower upper]
  (math.min upper (math.max lower v)))
