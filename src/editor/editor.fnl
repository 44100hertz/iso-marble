(var Editor (util.class))

(local UI (require :src.lib.UI))
(local LevelMap (require :src.LevelMap))

(fn Editor.constructor [{: screen-size} levelname]
  (love.keyboard.setKeyRepeat true)
  {:level (LevelMap levelname)
   :layer-index 1
   :camera {:center (Vec2 100 0) :zoom 4} ;; boundaries of camera
   :scroll-rate 8
   :show-layer false
   :drag-mode {}})

(fn Editor.instantiate [self]
  (set self.UI
       (UI [:node
            {:position (Vec2 0 0)
             :size (Vec2 40 80)
             :display [:image "src/editor/layerselect.png"]}
            [
              [:button
                {:position (Vec2 0 16)
                  :size (Vec2 40 32)
                  :onclick #(self:set-layer-relative -1)}]
              [:button
                {:position (Vec2 0 48)
                  :size (Vec2 40 32)
                  :onclick #(self:set-layer-relative 1)}]]]))
  (set self.event-handlers [self.UI self]))

(fn Editor.destructor []
  (love.keyboard.setKeyRepeat false))

(fn Editor.get-transform [self]
  (util.transform-from-list
   [:translate (/ (util.screen-size) 2)]
   [:scale self.camera.zoom]
   [:translate (- self.camera.center)]))

;; Perform function f with the boundaries of the current camera
(fn Editor.with-camera [self f]
  (util.with-transform (self:get-transform) f))

;; Scales the mouse position in accordance with zoom/scroll
(fn Editor.scale-mouse [self point]
  (let [tform (self:get-transform)]
    (Vec2 (tform:inverseTransformPoint point.x point.y))))

(fn Editor.get-mouse-tile [self pos]
  (self.level:get-tile-position-at (self:scale-mouse pos)))

(fn Editor.adjust-zoom [self offset center-point]
  (let [next-zoom (+ self.camera.zoom offset)]
   (if (and (>= next-zoom 0.5) (<= next-zoom 8))
    (do
      (set self.camera.zoom next-zoom)
      (when center-point
        (set self.camera.center
           (util.lume.lerp self.camera.center center-point 0.5)))))))

(fn Editor.set-layer [self layer]
  (set self.layer-index (util.clamp layer 0 self.level.map.size.y)))

(fn Editor.set-layer-relative [self amount]
  (self:set-layer (+ self.layer-index amount)))

(set Editor.key-binds
  (let [set-scroll
        (fn [self offset is-shifted]
          (set self.camera.center
               (+ self.camera.center
                  (* offset
                     self.scroll-rate
                     (if is-shifted 8 1)))))]
    {:q (fn [self] (self:set-layer-relative -1))
     :a (fn [self] (self:set-layer-relative 1))
     "=" #(Editor.adjust-zoom $1 1)
     "-" #(Editor.adjust-zoom $1 -1)
     :up (fn [self modifiers] (set-scroll self (Vec2 0 -1) modifiers.shift))
     :down (fn [self modifiers] (set-scroll self (Vec2 0 1) modifiers.shift))
     :left (fn [self modifiers] (set-scroll self (Vec2 -1 0) modifiers.shift))
     :right (fn [self modifiers] (set-scroll self (Vec2 1 0) modifiers.shift))}))

(fn Editor.draw-map [self]
  (for [i self.level.map.size.y 0 -1]
    (when (and self.show-layer (= i self.layer-index))
      (util.with-color-rgba 1 0 0 0.2
        (let [(x y) (love.window.getMode)]
          #(love.graphics.rectangle :fill 0 0 x y))))
    (self:with-camera #(self.level:draw-layer i))))

(fn Editor.draw [self]
  ;; draw map
  (self:draw-map util.screen-size)
  (self.UI:draw))

(fn Editor.update [self])

(fn Editor.keypressed [self scancode modifiers]
  (when (. self.key-binds scancode) ((. self.key-binds scancode) self modifiers)))

(fn Editor.mousepressed [self x y button]
  (if
   (= button 2)
   (self.level:delete-object-at (self:get-mouse-tile (Vec2 x y)))
   (= button 3)
   (set self.drag-mode {:type :scroll :last-pos (Vec2 x y)})))

(fn Editor.mousereleased [self x y]
  (set self.drag-mode {}))

(fn Editor.mousemoved [self x y]
  (case self.drag-mode.type
    nil (self.level:highlight-object-at (self:get-mouse-tile (Vec2 x y)))
    :scroll (do
              (set self.camera.center (- self.camera.center
                                        (/
                                         (- (Vec2 x y) self.drag-mode.last-pos)
                                         self.camera.zoom)))
              (set self.drag-mode.last-pos (Vec2 x y)))))

(fn Editor.wheelmoved [self x y]
  (let [mousepos (Vec2 (love.mouse.getPosition))]
    (self:adjust-zoom y (self:scale-mouse mousepos))))

Editor
