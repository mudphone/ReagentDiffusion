(ns diffusion.channel
  (:require
   [reagent.core :as reagent :refer [atom]]
   [cljsjs.phoenix]))

(defn create-socket []
  (new Phoenix.Socket "/socket" #js {:params #js {:token window.userToken}
                                   :logger #(.log js/console (str "w00t! " %1 ": " %2) %3)}))

(defn connect-socket! [socket]
  (.connect socket)
  socket)

(defn create-channel! [socket topic-name]
  (.channel socket topic-name))

(defn create-join-query-channel! [socket topic-name]
  (let [chan (create-channel! socket topic-name)]
    (-> chan
        (.join)
        (.receive "ok", (fn [resp]
                          (.log js/console (str "joined the " topic-name " channel") resp)))
        (.receive "error" (fn [reason]
                            (.log js/console "join failed" reason))))
    chan))
