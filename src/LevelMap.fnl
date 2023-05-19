(local LevelMap (util.class))

(fn LevelMap.constructor [levelname]
  (let [map (require (.. "levels/" levelname "/map"))]
    {: map
     :tile-gfx (love.graphics.newImage (.. "levels/" levelname "/tiles.png"))
     :tile-map {}
     :highlight-map {}
     :scroll (Vec2 80 0)}))

(fn LevelMap.instantiate [self]
  ;; copy tables to Vec3 where applicable
  (set self.map.size (Vec3 (unpack self.map.size)))
  (each [_i obj (ipairs self.map.objects)]
    (set obj.pos (Vec3 (unpack obj.pos)))
    (set obj.size (Vec3 (unpack obj.size))))
  ;; render objects into tile-map and color-map
  (each [_i obj-data (ipairs self.map.objects)]
        (self:render-object obj-data)))

(fn LevelMap.within-tile-bounds? [self {: x : y : z}]
  (and
   (>= x 0) (>= y 0) (>= z 0)
   (< x self.map.size.x) (< y self.map.size.y) (< z self.map.size.z)))

(fn LevelMap.tile-index [self {: x : y : z}]
  (+
   x
   (* self.map.size.x z)
   (* self.map.size.x self.map.size.z y)))

(fn LevelMap.render-object [self obj-data]
  (let [obj (require (.. "objects/" obj-data.type))]
    (obj.render {:set-tile #(self:set-tile obj-data $...)}
                obj-data)))

(fn LevelMap.highlight-object-at [self pos]
  (let [tile (self:get-tile pos)]
    (when tile
      (self:highlight-object tile.object))))

(fn LevelMap.highlight-object [self obj-data]
  (set self.highlight-map {})
  (let [obj (require (.. "objects/" obj-data.type))
        set-tile (lambda [pos _value _props]
                   (tset self.highlight-map (self:tile-index pos) true))]
    (obj.render {: set-tile}
                obj-data)))

(fn LevelMap.set-tile [self obj pos value props]
  (if (self:within-tile-bounds? pos)
      (do
        (let [tile-index (self:tile-index pos)]
          (tset self.tile-map tile-index
                {:object obj
                 :tile value
                 :color (. self :map :colormap props.color)})))
      (when (?. DEBUG :tiles)
        (DEBUG.warn-with-traceback "Attempt to set out of bounds tile" pos value))))

(fn LevelMap.get-tile [self pos]
  (let [index (self:tile-index pos)]
    (. self.tile-map index)))

(fn LevelMap.draw-tile [self pos]
  (let [tile-index (self:tile-index pos)
        tile (?. self.tile-map tile-index :tile)
        color (if (. self.highlight-map tile-index)
                  [1 0 0 1]
                  (?. self.tile-map tile-index :color))
        screen-pos (- (pos:project-to-screen) (Vec2 16 0))]
    (when (= tile 1)
      (love.graphics.setColor (if color (unpack color) (values 1 1 1 1)))
      (love.graphics.draw self.tile-gfx screen-pos.x screen-pos.y))))

(fn LevelMap.draw-layer [self layer-index]
  (for [z 0 (- self.map.size.z 1)]
    (for [x 0 (- self.map.size.x 1)]
      (self:draw-tile (Vec3 x layer-index z)))))

(fn LevelMap.draw-map [self]
  (for [i (length self.layers) 0 -1]
    (self:draw-layer i)))

LevelMap
