# app = angular.module("Zumin", ["ngResource"])
#
# @ConversationsCtrl = ($scope, $resource) ->
#   Conversation = $resource("/messages/:id.json", {id: "@id"}, {update: {method: "PUT"}})
#   $scope.conversations = Conversation.query()
#   $scope.show_conversations = true
#
#   $scope.open_conversation = (conversation) ->
#     $scope.show_conversations = false
#     $scope.show_single_conversation = true
#     $scope.messages = conversation.messages
#
#   $scope.close_conversation = ->
#     $scope.show_conversations = true
#     $scope.show_single_conversation = false