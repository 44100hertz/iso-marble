(import-macros {: incf} "src/lib/macros")

(local Viewer (util.class))

(fn Viewer.constructor [levelname]
   {:map (require (.. "levels/" levelname "/map"))
    :tile-gfx (love.graphics.newImage (.. "levels/" levelname "/tiles.png"))})

(fn Viewer.draw-layer [self index]
  (let [tiles (. self.map :layers index :tiles)]
    (for [z 0 (- self.map.zsize 1)]
      (for [x 1 self.map.xsize]
        (let [tile (. tiles (+ (* z self.map.zsize) x))
              (screen-x screen-y) (util.iso-to-screen x (- index 1) z)]
          (when (= tile 1) (love.graphics.draw self.tile-gfx screen-x screen-y)))))))

(fn Viewer.draw-map [self]
  (for [i (length self.map.layers) 1 -1]
    (self:draw-layer i)))

(fn Viewer.draw [self]
  (love.graphics.clear 0 0 0)
  (love.graphics.translate 80 0)
  (self:draw-map self.map))
(fn Viewer.update [self])
(fn Viewer.keypressed [self])

Viewer
