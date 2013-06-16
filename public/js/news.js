var SN = SN || {};

SN.viewModels = (function() {

  var Celebs,
      Top,
      More,
      CelebListViewModel,
      TopStoryViewModel,
      MoreListViewModel,
      init;

  // sidebar stories
  Celebs = function Celebs(data) {
    this.title = data.title;
    this.text = data.text;
    this.photo_url = data.photo_url;
  };

  // top story
  Top = function Top(data) {
    this.title = data.title;
    this.text = data.text;
    this.photo_url = data.photo_url;
  };


  // more stories
  More = function More(data) {
    this.title = data.title;
    this.text = data.text;
    this.photo_url = data.photo_url;
  };

  CelebListViewModel = function CelebListViewModel() {
    var self = this;
    self.celebs = ko.observableArray([]);

    $.getJSON("/articles/3", function(allData) {
      var mappedCelebs = $.map(allData, function(article) { return new Celebs(article); });
      self.celebs(mappedCelebs);
    });
  };

  TopStoryViewModel = function TopStoryViewModel() {
    var self = this;
    self.topStory = ko.observable({});

    $.getJSON("/articles/1/8", function(data) {
      // only deal with the first result
      self.topStory (new Top(data[0]));
    });

  };

  MoreListViewModel = function MoreListViewModel() {
    var self = this;
    self.moreStories = ko.observableArray([]);

    $.getJSON("/articles/5/10", function(allData) {
      var mappedTopStories = $.map(allData, function(article) { return new More(article); });
      self.moreStories(mappedTopStories);
    });
  };

  init = function init() {
    ko.applyBindings(new CelebListViewModel(), document.getElementById('celebrity-news'));
    ko.applyBindings(new MoreListViewModel(), document.getElementById('more-stories'));
    ko.applyBindings(new TopStoryViewModel(), document.getElementById('top-story'));
  };

  return {
    init: init
  };

}());