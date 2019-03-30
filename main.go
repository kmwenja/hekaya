package main

import (
	"encoding/json"
	"log"
	"net/http"
)

type uiDir struct {
	http.FileSystem
	index string
}

func (d *uiDir) Open(name string) (http.File, error) {
	f, err := d.FileSystem.Open(name)
	if err != nil {
		return d.FileSystem.Open(d.index)
	}
	return f, err
}

type postEntry struct {
	Id          int    `json:"id"`
	Title       string `json:"title"`
	Description string `json:"description"`
	Author      string `json:"author"`
	Date        string `json:"date"`
}

type post struct {
	Id     int    `json:"id"`
	Title  string `json:"title"`
	Body   string `json:"body"`
	Author string `json:"author"`
	Date   string `json:"date"`
}

func postListApi(w http.ResponseWriter, r *http.Request) {
	entries := []postEntry{
		postEntry{
			Id:          1,
			Title:       "Hello World!",
			Description: "First ever post on this blog",
			Author:      "rexxor",
			Date:        "30th March 2019",
		},
	}
	enc := json.NewEncoder(w)
	if err := enc.Encode(&entries); err != nil {
		http.Error(w, "Internal error", http.StatusInternalServerError)
		return
	}
}

func postApi(w http.ResponseWriter, r *http.Request) {
	p := post{
		Id:     1,
		Title:  "Hello World!",
		Body:   "First ever post on this blog",
		Author: "rexxor",
		Date:   "30th March 2019",
	}
	enc := json.NewEncoder(w)
	if err := enc.Encode(&p); err != nil {
		http.Error(w, "Internal error", http.StatusInternalServerError)
		return
	}
}

func main() {
	ui := &uiDir{http.Dir("ui"), "index.html"}
	http.HandleFunc("/api/posts/1", postApi)
	http.HandleFunc("/api/posts/", postListApi)
	http.Handle("/", http.FileServer(ui))
	log.Fatal(http.ListenAndServe(":8080", nil))
}
