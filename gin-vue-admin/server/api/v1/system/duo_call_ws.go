package system

import (
	"net/http"
	"sync"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

type duoSocketClient struct {
	slot uint
	conn *websocket.Conn
	send chan []byte
}

var duoSocketHub = struct {
	sync.RWMutex
	clients map[*duoSocketClient]struct{}
}{clients: make(map[*duoSocketClient]struct{})}
var duoUpgrader = websocket.Upgrader{CheckOrigin: func(_ *http.Request) bool { return true }}

func (a *DuoCallApi) WebSocket(c *gin.Context) {
	claims, ok := duoAuth(c)
	if !ok {
		return
	}
	conn, err := duoUpgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		return
	}
	client := &duoSocketClient{slot: claims.Slot, conn: conn, send: make(chan []byte, 32)}
	duoSocketHub.Lock()
	duoSocketHub.clients[client] = struct{}{}
	duoSocketHub.Unlock()
	go func() {
		defer conn.Close()
		for message := range client.send {
			if conn.WriteMessage(websocket.TextMessage, message) != nil {
				return
			}
		}
	}()
	defer func() {
		duoSocketHub.Lock()
		delete(duoSocketHub.clients, client)
		close(client.send)
		duoSocketHub.Unlock()
	}()
	for {
		_, message, err := conn.ReadMessage()
		if err != nil {
			return
		}
		duoSocketHub.RLock()
		for peer := range duoSocketHub.clients {
			if peer != client {
				select {
				case peer.send <- message:
				default:
				}
			}
		}
		duoSocketHub.RUnlock()
	}
}
