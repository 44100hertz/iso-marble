(fn inc [value ?by]
  `(set ,value (+ ,value (or ,?by 1))))

(fn dec [value ?by]
  `(set ,value (- ,value (or ,?by 1))))

(fn with [t keys ?body]
  `(let [,keys ,t]
     (if ,?body
         ,?body
         ,keys)))

{: inc : dec : with}
