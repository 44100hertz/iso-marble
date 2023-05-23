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
   :panning false
   :mode {}})

(fn Editor.instantiate [self]
  (set self.UI
       (UI
        [:node
         {:position (Vec2 0 0)
          :size (Vec2 0 0)}
         [
          [:node
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
              :onclick #(self:set-layer-relative 1)}]]]
          [:button
           {:position (Vec2 40 0)
            :size (Vec2 64 64)
            :display [:image-quad "src/editor/delete.png" 0 0 32 32]
            :watch [self :mode]
            :update
            (fn [elem]
            ;; increase the x of the image quad
             (tset (. elem 2 :display) 3
                   (case self.mode
                     {:type nil} 0
                     {:type :delete :many false} 32
                     {:type :delete :many true} 64)))
            :onclick #(self:next-delete-mode)}]]]))
  (set self.event-handlers [self.UI self]))

(fn Editor.destructor []
  (love.keyboard.setKeyRepeat false))

;; cycle thru delete modes
(fn Editor.next-delete-mode [self]
  (set self.mode
       (case self.mode
         {:type nil} {:type :delete :many false}
         {:type :delete :many false} {:type :delete :many true}
         {:type :delete :many true} {})))

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
     :x #(Editor.next-delete-mode $1)
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
   (= button 3)
   (set self.panning {:last-pos (Vec2 x y)})
   (= self.mode.type :delete)
   (do
     (self.level:delete-object-at (self:get-mouse-tile (Vec2 x y)))
     (if (not self.mode.many)
         (set self.mode {})))))

(fn Editor.mousereleased [self x y]
  (if self.panning (set self.panning false)))

(fn Editor.mousemoved [self x y]
  (if self.panning
    (do
      (set self.camera.center (- self.camera.center
                                (/
                                 (- (Vec2 x y) self.panning.last-pos)
                                 self.camera.zoom)))
      (set self.panning.last-pos (Vec2 x y)))
    (case self.mode.type
      nil
      (self.level:highlight-object-at (self:get-mouse-tile (Vec2 x y)) [0 1 1])
      :delete
      (self.level:highlight-object-at (self:get-mouse-tile (Vec2 x y)) [1 0 0]))))

(fn Editor.wheelmoved [self x y]
  (let [mousepos (Vec2 (love.mouse.getPosition))]
    (self:adjust-zoom y (self:scale-mouse mousepos))))

Editor
