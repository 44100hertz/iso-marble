{
 :render (fn [{: set-tile} {: pos : size}]
           (for [x pos.x (+ size.x pos.x)]
             (for [y pos.y (+ size.y pos.y)]
               (for [z pos.z (+ size.z pos.z)]
                 (set-tile (Vec3 x y z) 1)))))}
