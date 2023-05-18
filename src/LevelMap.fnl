(local LevelMap (util.class))

(fn LevelMap.constructor [levelname]
  (let [map (require (.. "levels/" levelname "/map"))]
    {:map {:size (Vec3 (unpack map.size))
           :objects (icollect [_i {: type : pos : size} (ipairs map.objects)]
                      {: type
                       :pos (Vec3 (unpack pos))
                       :size (Vec3 (unpack size))})}
     :tile-gfx (love.graphics.newImage (.. "levels/" levelname "/tiles.png"))
     :tiles {}
     :scroll (Vec2 80 0)}))

(fn LevelMap.instantiate [self]
  (each [_i obj-data (ipairs self.map.objects)]
    (let [obj (require (.. "objects/" obj-data.type))]
      (obj.render {:set-tile #(self:set-tile $...)}
                  obj-data))))

(fn LevelMap.within-tile-bounds? [self {: x : y : z}]
  (and
   (>= x 0) (>= y 0) (>= z 0)
   (< x self.map.size.x) (< y self.map.size.y) (< z self.map.size.z)))

(fn LevelMap.tile-index [self {: x : y : z}]
  (+
   x
   (* self.map.size.x z)
   (* self.map.size.x self.map.size.z y)))

(fn LevelMap.set-tile [self pos value]
  (if (self:within-tile-bounds? pos)
    (tset self.tiles (self:tile-index pos) value)
    (when (?. DEBUG :tiles)
      (DEBUG.warn-with-traceback "Attempt to set out of bounds tile" pos value))))

(fn LevelMap.draw-layer [self layer-index]
  (for [z 0 (- self.map.size.z 1)]
    (for [x 0 (- self.map.size.x 1)]
      (let [pos (Vec3 x layer-index z)
            tile (. self.tiles (self:tile-index pos))
            screen-pos (- (pos:project-to-screen) (Vec2 16 0))]
        (when (= tile 1) (love.graphics.draw self.tile-gfx screen-pos.x screen-pos.y))))))

(fn LevelMap.draw-map [self]
  (for [i (length self.layers) 0 -1]
    (self:draw-layer i)))

LevelMap
