(fn ++ [value ?by]
  `(set ,value (+ ,value (or ,?by 1))))

(fn -- [value ?by]
  `(set ,value (- ,value (or ,?by 1))))

(fn with [t keys ?body]
  `(let [,keys ,t]
     (if ,?body
         ,?body
         ,keys)))

{: ++ : -- : with}
