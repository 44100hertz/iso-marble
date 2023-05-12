(set _G.util {})
(fn _G.util.iso-to-screen [x y z]
  (values (* 16 (- z x))
          (* 16 (+ y (/ (+ x z) 2)))))

(fn _G.util.class [class]
  (let [class (if class class {})]
    (set class.mt {:__index class})
    (setmetatable class {:__call
                         (fn [_class ...]
                           (setmetatable (class.constructor ...) class.mt))})
    class))
