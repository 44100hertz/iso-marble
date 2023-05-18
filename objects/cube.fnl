{
 :render (fn [{: set-tile} {: pos : size &as props}]
           (for [x pos.x (+ size.x pos.x -1)]
             (for [y pos.y (+ size.y pos.y -1)]
               (for [z pos.z (+ size.z pos.z -1)]
                 (set-tile (Vec3 x y z) 1 props)))))}
