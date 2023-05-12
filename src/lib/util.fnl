(set _G.util {})
(fn _G.util.iso-to-screen [x y z]
  (values (* 16 (- z x))
          (* 16 (+ y (/ (+ x z) 2)))))

(fn _G.util.class [t]
  (let [t (if t t {})]
    (fn t.new [...] (setmetatable (t.constructor ...) {:__index t}))
    t))
