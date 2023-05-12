(import-macros {: incf} "src/lib/macros")

(local LevelMap (util.class))

(fn LevelMap.constructor [levelname]
   {:map (require (.. "levels/" levelname "/map"))
    :tile-gfx (love.graphics.newImage (.. "levels/" levelname "/tiles.png"))
    :scroll {:x 80 :y 0}})

(fn LevelMap.draw-layer [self index]
  (let [tiles (. self.map :layers index :tiles)]
    (for [z 0 (- self.map.zsize 1)]
      (for [x 1 self.map.xsize]
        (let [tile (. tiles (+ (* z self.map.zsize) x))
              (screen-x screen-y) (util.iso-to-screen x (- index 1) z)]
          (when (= tile 1) (love.graphics.draw self.tile-gfx screen-x screen-y)))))))

(fn LevelMap.draw-map [self]
  (for [i (length self.map.layers) 1 -1]
    (self:draw-layer i)))

LevelMap
