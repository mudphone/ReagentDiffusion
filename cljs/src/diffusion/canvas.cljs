(ns diffusion.canvas
  (:require
   [reagent.core :as reagent :refer [atom]]))

(defonce grid (reagent/atom {}))

(defn draw-canvas-contents [ canvas ]
  (let [ctx (.getContext canvas "2d")
        w   (.-clientWidth canvas)
        h   (.-clientHeight canvas)]
    (.beginPath ctx)
    (.moveTo ctx 0 0)
    (.lineTo ctx w h)
    (.moveTo ctx w 0)
    (.lineTo ctx 0 h)
    (.stroke ctx)))

(defn div-with-canvas [width height]
  (let [dom-node (reagent/atom nil)]
    (reagent/create-class
     {:component-did-update
      (fn [ this ]
        (draw-canvas-contents (.-firstChild @dom-node)))

      :component-did-mount
      (fn [ this ]
        (reset! dom-node (reagent/dom-node this)))

      :reagent-render
      (fn [ ]
        @grid ;; Trigger re-render on window resizes
        
        [:div.with-canvas
         ;; reagent-render is called before the compoment mounts, so
         ;; protect against the null dom-node that occurs on the first
         ;; render
         [:canvas (if-let [ node @dom-node ]
                    {:width width
                     :height height}
                    ;; {:width (.-clientWidth node)
                    ;;  :height (.-clientHeight node)}
                    )]])})))
