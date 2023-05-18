(local LevelMap (util.class))

(fn LevelMap.tile-index [self x z] (+ (* self.map.size.z z) x))

(fn LevelMap.set-tile [self {: x : y : z} v]
  (tset (. self :layers y :tiles) (self:tile-index x z) v))

(fn LevelMap.constructor [levelname]
  (let [map (require (.. "levels/" levelname "/map"))]
    {:map {:size (Vec3 (unpack map.size))
           :objects (icollect [_i {: type : pos : size} (ipairs map.objects)]
                      {: type
                       :pos (Vec3 (unpack pos))
                       :size (Vec3 (unpack size))})}
     :tile-gfx (love.graphics.newImage (.. "levels/" levelname "/tiles.png"))
     :scroll (Vec2 80 0)}))

(fn LevelMap.instantiate [self]
  (set self.layers (fcollect [_i 1 self.map.size.y] {:tiles {}}))
  (each [_i obj-data (ipairs self.map.objects)]
    (let [obj (require (.. "objects/" obj-data.type))]
     (obj.render {:set-tile #(self:set-tile $...)}
       obj-data))))

(fn LevelMap.draw-layer [self index]
  (let [tiles (. self.layers index :tiles)]
    (for [z 0 (- self.map.size.z 1)]
      (for [x 1 self.map.size.x]
        (let [tile (. tiles (+ (* z self.map.size.z) x))
              tile-pos (Vec3 x (- index 1) z)
              screen-pos (tile-pos:project-to-screen)]
          (when (= tile 1) (love.graphics.draw self.tile-gfx screen-pos.x screen-pos.y)))))))

(fn LevelMap.draw-map [self]
  (for [i (length self.layers) 1 -1]
    (self:draw-layer i)))

LevelMap
