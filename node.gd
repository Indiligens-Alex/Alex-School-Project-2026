extends HTTPRequest

@export var data: PackedStringArray
@export var url: String

func _ready() -> void:
	# Connects the HTTP Node to a function which porccesses its data
	request_completed.connect(_on_request_completed)
	request("https://myself-fruck2-band.plaky.com/spaces/199567/boards/239577/views/390410/items/5244106#attributes")

## Outputs the recieved web data
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var response = body.get_string_from_utf8()
	print(response)
	#var json: Dictionary = JSON.parse_string(body.get_string_from_utf8())
	#print(json["name"])
	#print(body)

	#print(type_string(json))

#func send() -> void:
	#var json: Dictionary = JSON.stringify(data_to_send)
	#var headers = ["Content-Type: application/json"]
	#request(url, headers, HTTPClient.METHOD_POST, json)
