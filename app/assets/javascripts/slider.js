(function (a) {
    function b(b, c) {
        this.slider = a(b);
        this._downEvent = "";
        this._moveEvent = "";
        this._upEvent = "";
        var d = this;
        this.settings = a.extend({}, a.fn.royalSlider.defaults, c);
        this.isSlideshowRunning = false;
        this._slideshowHoverLastState = false;
        this._dragContainer = this.slider.find(".royalSlidesContainer");
        this._slidesWrapper = this._dragContainer.wrap('<div class="royalWrapper"/>').parent();
        this.slides = this._dragContainer.find(".royalSlide");
        this._preloader = "<p class='royalPreloader'></p>";
        this._successfullyDragged = false;
        this._useWebkitTransition = false;
        if ("ontouchstart" in window) {
            if (!this.settings.disableTranslate3d) {
                if ("WebKitCSSMatrix" in window && "m11" in new WebKitCSSMatrix) {
                    this._dragContainer.css({
                        "-webkit-transform-origin": "0 0",
                        "-webkit-transform": "translateZ(0)"
                    });
                    this._useWebkitTransition = true
                }
            }
            this.hasTouch = true;
            this._downEvent = "touchstart.rs";
            this._moveEvent = "touchmove.rs";
            this._upEvent = "touchend.rs"
        } else {
            this.hasTouch = false;
            if (this.settings.dragUsingMouse) {
                this._downEvent = "mousedown.rs";
                this._moveEvent = "mousemove.rs";
                this._upEvent = "mouseup.rs"
            } else {
                this._dragContainer.addClass("auto-cursor")
            }
        }
        if (this.hasTouch) {
            this.settings.directionNavAutoHide = false;
            this.settings.hideArrowOnLastSlide = true
        }
        if (a.browser.msie && parseInt(a.browser.version) <= 8) {
            this._isIE8 = true
        } else {
            this._isIE8 = false
        }
        this.slidesArr = [];
        var e, f, g, h;
        this.slides.each(function () {
            f = a(this);
            e = {};
            e.slide = f;
            if (d.settings.blockLinksOnDrag) {
                if (!this.hasTouch) {
                    f.find("a").bind("click.rs", function (a) {
                        if (d._successfullyDragged) {
                            a.preventDefault();
                            return false
                        }
                    })
                } else {
                    var b = f.find("a");
                    var c;
                    b.each(function () {
                        c = a(this);
                        c.data("royalhref", c.attr("href"));
                        c.data("royaltarget", c.attr("target"));
                        c.attr("href", "#");
                        c.bind("click", function (b) {
                            b.preventDefault();
                            if (d._successfullyDragged) {
                                return false
                            } else {
                                var c = a(this).data("royalhref");
                                var e = a(this).data("royaltarget");
                                if (!e || e.toLowerCase() === "_self") {
                                    window.location.href = c
                                } else {
                                    window.open(c)
                                }
                            }
                        })
                    })
                }
            }
            if (d.settings.nonDraggableClassEnabled) {
                f.find(".non-draggable").bind(d._downEvent, function (a) {
                    d._successfullyDragged = false;
                    a.stopImmediatePropagation()
                })
            }
            g = f.attr("data-src");
            if (g == undefined || g == "" || g == "none") {
                e.preload = false
            } else {
                e.preload = true;
                e.preloadURL = g
            }
            if (d.settings.captionAnimationEnabled) {
                e.caption = f.find(".royalCaption").css("display", "none")
            }
            d.slidesArr.push(e)
        });
        this._removeFadeAnimation = false;
        if (this.settings.removeCaptionsOpacityInIE8) {
            if (a.browser.msie && parseInt(a.browser.version, 10) <= 8) {
                this._removeFadeAnimation = true
            }
        }
        this.slider.css("overflow", "visible");
        this.slideWidth = 0;
        this.slideHeight = 0;
        this.slideshowTimer = "";
        this._alreadyStoped = false;
        this.numSlides = this.slides.length;
        this.currentSlideId = this.settings.startSlideIndex;
        this.lastSlideId = -1;
        this.isAnimating = true;
        this.wasSlideshowPlaying = false;
        this._currentDragPosition = 0;
        this._lastDragPosition = 0;
        this._blockThumbnailsScroll = false;
        this._captionAnimateTimeouts = [];
        this._captionAnimateProperties = [];
        this._blockClickEvents = false;
        this._dragBlocked = false;
        this._tx = 0;
        this._startMouseX = 0;
        this._startMouseY = 0;
        this._startPos = 0;
        this._isDragging = false;
        this._isHovering = false;
        if (this.settings.slideTransitionType === "fade") {
            if (this._useWebkitTransition || "WebKitCSSMatrix" in window && "m11" in new WebKitCSSMatrix) {
                this._animateCSS3Opacity = true
            } else {
                this._animateCSS3Opacity = false
            }
            this._fadeContainer = a("<div class='fade-container'></div>").appendTo(this._slidesWrapper)
        }
        if (this.settings.slideshowEnabled && this.settings.slideshowDelay > 0) {
            if (!this.hasTouch && this.settings.slideshowPauseOnHover) {
                this.slider.hover(function () {
                    d._isHovering = true;
                    d._stopSlideshow(true)
                }, function () {
                    d._isHovering = false;
                    d._resumeSlideshow(true)
                })
            }
            this.slideshowEnabled = true
        } else {
            this.slideshowEnabled = false
        }
        this._setGrabCursor();
        if (this.settings.controlNavEnabled) {
            var i;
            this._navigationContainer = "";
            var j;
            if (!d.settings.controlNavThumbs) {
                this._navigationContainer = a('<div class="royalControlNavOverflow"><div class="royalControlNavContainer"><div class="royalControlNavCenterer"></div></div></div>');
                i = this._navigationContainer.find(".royalControlNavCenterer")
            } else {
                this.slider.addClass("with-thumbs");
                if (d.settings.controlNavThumbsNavigation) {
                    j = a('<div class="thumbsAndArrowsContainer"></div>');
                    this.thumbsArrowLeft = a("<a href='#' class='thumbsArrow left'></a>");
                    this.thumbsArrowRight = a("<a href='#' class='thumbsArrow right'></a>");
                    j.append(this.thumbsArrowLeft);
                    j.append(this.thumbsArrowRight);
                    var k = parseInt(this.thumbsArrowLeft.outerWidth(), 10);
                    this._navigationContainer = a('<div class="royalControlNavOverflow royalThumbs"><div class="royalControlNavThumbsContainer"></div></div>');
                    i = this._navigationContainer.find(".royalControlNavThumbsContainer")
                } else {
                    this._navigationContainer = a('<div class="royalControlNavOverflow royalThumbs"><div class="royalControlNavContainer"><div class="royalControlNavCenterer"></div></div></div>');
                    i = this._navigationContainer.find(".royalControlNavCenterer")
                }
            }
            var l = 0;
            this.slides.each(function (b) {
                if (d.settings.controlNavThumbs) {
                    i.append('<a href="#" class="royalThumb" style="background-image:url(' + a(this).attr("data-thumb") + ')">' + (b + 1) + "</a>")
                } else {
                    i.append('<a href="#">' + (b + 1) + "</a>")
                }
                l++
            });
            this.navItems = i.children();
            if (j) {
                j.append(this._navigationContainer);
                this._slidesWrapper.after(j)
            } else {
                this._slidesWrapper.after(this._navigationContainer)
            }
            if (d.settings.controlNavThumbs && d.settings.controlNavThumbsNavigation) {
                this._thumbsArrowLeftBlocked = true;
                this._thumbsArrowRightBlocked = false;
                this._thumbsNavContainer = i;
                if (this._useWebkitTransition) {
                    this._thumbsNavContainer.css({
                        "-webkit-transition-duration": this.settings.controlNavThumbsSpeed + "ms",
                        "-webkit-transition-property": "-webkit-transform",
                        "-webkit-transition-timing-function": "ease-in-out"
                    })
                }
                this._numThumbItems = l;
                var m = this.navItems.eq(0);
                this._outerThumbWidth = m.outerWidth(true);
                this._thumbsTotalWidth = this._outerThumbWidth * this._numThumbItems;
                this._thumbsNavContainer.css("width", this._thumbsTotalWidth);
                this._thumbsSpacing = parseInt(m.css("marginRight"), 10);
                this._thumbsTotalWidth -= this._thumbsSpacing;
                this._currThumbsX = 0;
                this._recalculateThumbsScroller();
                this.thumbsArrowLeft.click(function (a) {
                    a.preventDefault();
                    if (!d._thumbsArrowLeftBlocked) d._animateThumbs(d._currThumbsX + d._thumbsContainerWidth + d._thumbsSpacing)
                });
                this.thumbsArrowRight.click(function (a) {
                    a.preventDefault();
                    if (!d._thumbsArrowRightBlocked) d._animateThumbs(d._currThumbsX - d._thumbsContainerWidth - d._thumbsSpacing)
                })
            }
            this._updateControlNav()
        }
        if (this.settings.directionNavEnabled) {
            	this._slidesWrapper.after("<a href='#' class='arrow left'/>");
			this._slidesWrapper.after("<a href='#' class='arrow right'/>");


			this.arrowLeft = this.slider.find("a.arrow.left");
			this.arrowRight = this.slider.find("a.arrow.right");
			
			
            if (this.arrowLeft.length < 1 || this.arrowRight.length < 1) {
                this.settings.directionNavEnabled = false
            } else if (this.settings.directionNavAutoHide) {
                this.arrowLeft.hide();
                this.arrowRight.hide();
                this.slider.one("mousemove.arrowshover", function () {
                    d.arrowLeft.fadeIn("fast");
                    d.arrowRight.fadeIn("fast")
                });
                this.slider.hover(function () {
                    d.arrowLeft.fadeIn("fast");
                    d.arrowRight.fadeIn("fast")
                }, function () {
                    d.arrowLeft.fadeOut("fast");
                    d.arrowRight.fadeOut("fast")
                })
            }
            this._updateDirectionNav()
        }
        this.sliderWidth = 0;
        this.sliderHeight = 0;
        var n;
        this._resizeEvent = "onorientationchange" in window ? "orientationchange.royalslider" : "resize.royalslider";
        a(window).bind(this._resizeEvent, function () {
            if (n) clearTimeout(n);
            n = setTimeout(function () {
                d.updateSliderSize()
            }, 100)
        });
        this.updateSliderSize();
        this.settings.beforeLoadStart.call(this);
        var o = this.slidesArr[this.currentSlideId];
        if (this.currentSlideId != 0) {
            if (!this._useWebkitTransition) {
                this._dragContainer.css({
                    left: -this.currentSlideId * this.slideWidth
                })
            } else {
                this._dragContainer.css({
                    "-webkit-transition-duration": "0ms",
                    "-webkit-transition-property": "none"
                });
                this._dragContainer.css({
                    "-webkit-transform": "translate3d(" + -this.currentSlideId * this.slideWidth + "px, 0, 0)"
                })
            }
        }
        if (this.settings.welcomeScreenEnabled) {
            function p(a) {
                d.settings.loadingComplete.call(d);
                if (a && d.settings.preloadNearbyImages) {
                    d._preloadNearbyImages(d.currentSlideId)
                }
                d.slider.find(".royalLoadingScreen").fadeOut(d.settings.welcomeScreenShowSpeed);
                setTimeout(function () {
                    d._startSlider()
                }, d.settings.welcomeScreenShowSpeed + 100)
            }
            if (o.preload) {
                this._preloadNearbyImages(this.currentSlideId, function () {
                    p(false)
                })
            } else {
                var h = o.slide.find("img.royalImage")[0];
                if (h) {
                    if (this._isImageLoaded(h)) {
                        p(true);
                        a(h).css("opacity", 0);
                        a(h).animate({
                            opacity: 1
                        }, "fast")
                    } else {
                        a(h).css("opacity", 0);
                        a("<img />").load(function () {
                            p(true);
                            a(h).animate({
                                opacity: 1
                            }, "fast")
                        }).attr("src", h.src)
                    }
                } else {
                    p(true)
                }
            }
        } else {
            if (o.preload) {
                this._preloadImage(o, function () {
                    d.settings.loadingComplete.call(d);
                    if (d.settings.preloadNearbyImages) {
                        d._preloadNearbyImages(d.currentSlideId)
                    }
                })
            } else {
                var h = o.slide.find("img.royalImage")[0];
                if (h) {
                    if (this._isImageLoaded(h)) {
                        a(h).css("opacity", 0).animate({
                            opacity: 1
                        }, "fast")
                    } else {
                        a(h).css("opacity", 0);
                        a("<img />").load(function () {
                            a(h).animate({
                                opacity: 1
                            }, "fast")
                        }).attr("src", h.src)
                    }
                }
                this.settings.loadingComplete.call(this)
            }
            setTimeout(function () {
                d._startSlider()
            }, 100)
        }
    }
    b.prototype = {
        goTo: function (a, b, c, d) {
            if (!this.isAnimating) {
                this.isAnimating = true;
                var e = this;
                this.lastSlideId = this.currentSlideId;
                this.currentSlideId = a;
                this._dragBlocked = true;
                this._blockClickEvents = true;
                if (this.lastSlideId != a) {
                    this._updateControlNav(c);
                    this._preloadNearbyImages(a)
                }
                this._updateDirectionNav();
                this.settings.beforeSlideChange.call(this);
                if (this.slideshowEnabled && this.slideshowTimer) {
                    this.wasSlideshowPlaying = true;
                    this._stopSlideshow()
                }
                var f = !b ? this.settings.slideTransitionSpeed : 0;
                if (d || b || this.settings.slideTransitionType === "move") {
                    if (!this._useWebkitTransition) {
                        if (parseInt(this._dragContainer.css("left"), 10) !== -this.currentSlideId * this.slideWidth) {
                            this._dragContainer.animate({
                                left: -this.currentSlideId * this.slideWidth
                            }, f, this.settings.slideTransitionEasing, function () {
                                e._onSlideAnimationComplete()
                            })
                        } else {
                            this._onSlideAnimationComplete()
                        }
                    } else {
                        if (this._getWebkitTransformX() !== -this.currentSlideId * this.slideWidth) {
                            this._dragContainer.bind("webkitTransitionEnd", function (a) {
                                if (a.target == e._dragContainer.get(0)) {
                                    e._onSlideAnimationComplete();
                                    e._dragContainer.unbind("webkitTransitionEnd")
                                }
                            });
                            this._dragContainer.css({
                                "-webkit-transition-duration": f + "ms",
                                "-webkit-transition-property": "-webkit-transform",
                                "-webkit-transition-timing-function": "ease-in-out",
                                "-webkit-transform": "translate3d(" + -this.currentSlideId * this.slideWidth + "px, 0, 0)"
                            })
                        } else {
                            this._onSlideAnimationComplete()
                        }
                    }
                } else {
                    var g = this.slidesArr[this.lastSlideId].slide;
                    var h = g.clone().appendTo(this._fadeContainer);
                    if (!this._animateCSS3Opacity) {
                        this._dragContainer.css({
                            left: -this.currentSlideId * this.slideWidth
                        });
                        h.animate({
                            opacity: 0
                        }, f, this.settings.slideTransitionEasing, function () {
                            h.remove();
                            e._onSlideAnimationComplete()
                        })
                    } else {
                        if (!this._useWebkitTransition) {
                            this._dragContainer.css({
                                left: -this.currentSlideId * this.slideWidth
                            })
                        } else {
                            this._dragContainer.css({
                                "-webkit-transition-duration": "0",
                                "-webkit-transform": "translate3d(" + -this.currentSlideId * this.slideWidth + "px, 0, 0)",
                                opacity: "1"
                            })
                        }
                        setTimeout(function () {
                            h.bind("webkitTransitionEnd", function (a) {
                                if (a.target == h.get(0)) {
                                    h.unbind("webkitTransitionEnd");
                                    h.remove();
                                    e._onSlideAnimationComplete()
                                }
                            });
                            h.css({
                                "-webkit-transition-duration": f + "ms",
                                "-webkit-transition-property": "opacity",
                                "-webkit-transition-timing-function": "ease-in-out"
                            });
                            h.css("opacity", 0)
                        }, 100)
                    }
                }
            }
        },
        goToSilent: function (a) {
            this.goTo(a, true)
        },
        prev: function () {
            if (this.currentSlideId <= 0) {
                this.goTo(this.numSlides - 1)
            } else {
                this._moveSlideLeft()
            }
        },
        next: function () {
            if (this.currentSlideId >= this.numSlides - 1) {
                this.goTo(0)
            } else {
                this._moveSlideRight()
            }
        },
        updateSliderSize: function () {
            var a = this;
            this.sliderWidth = 508;
            this.sliderHeight = this.slider.height();
            if (this.sliderWidth != this.slideWidth || this.sliderHeight != this.slideHeight) {
                this.slideWidth = this.sliderWidth + this.settings.slideSpacing;
                var b = this.slidesArr.length;
                var c, d;
                for (var e = 0, f = b; e < f; ++e) {
                    c = this.slidesArr[e];
                    d = c.slide.find("img.royalImage").eq(0);
                    if (d && c.preload == false) {
                        this._scaleImage(d, this.sliderWidth, this.sliderHeight)
                    }
                    if (this.settings.slideSpacing > 0 && e < b - 1) {
                        c.slide.css("cssText", "margin-right:" + this.settings.slideSpacing + "px !important;")
                    }
                    c.slide.css({
                        height: a.sliderHeight,
                        width: a.sliderWidth
                    })
                }
                if (!this._useWebkitTransition) {
                    this._dragContainer.css({
                        left: -this.currentSlideId * this.slideWidth,
                        width: this.slideWidth * this.numSlides
                    })
                } else {
                    this._dragContainer.css({
                        "-webkit-transition-duration": "0ms",
                        "-webkit-transition-property": "none"
                    });
                    this._dragContainer.css({
                        "-webkit-transform": "translate3d(" + -this.currentSlideId * this.slideWidth + "px, 0, 0)",
                        width: this.slideWidth * this.numSlides
                    })
                }
                if (this.settings.controlNavThumbs && this.settings.controlNavThumbsNavigation) {
                    this._recalculateThumbsScroller()
                }
            }
        },
        stopSlideshow: function () {
            this._stopSlideshow();
            this.slideshowEnabled = false;
            this.wasSlideshowPlaying = false
        },
        resumeSlideshow: function () {
            this.slideshowEnabled = true;
            if (!this.wasSlideshowPlaying) {
                this._resumeSlideshow()
            }
        },
        destroy: function () {
            this._stopSlideshow();
            this._dragContainer.unbind(this._downEvent);
            a(document).unbind(this._moveEvent).unbind(this._upEvent);
            a(window).unbind(this._resizeEvent);
            if (this.settings.keyboardNavEnabled) {
                a(document).unbind("keydown.rs")
            }
            this.slider.remove();
            delete this.slider
        },
        _preloadNearbyImages: function (a, b) {
            if (this.settings.preloadNearbyImages) {
                var c = this;
                this._preloadImage(this.slidesArr[a], function () {
                    if (b) {
                        b.call()
                    }
                    c._preloadImage(c.slidesArr[a + 1], function () {
                        c._preloadImage(c.slidesArr[a - 1])
                    })
                })
            } else {
                this._preloadImage(this.slidesArr[a], b)
            }
        },
        _updateControlNav: function (a) {
            if (this.settings.controlNavEnabled) {
                this.navItems.eq(this.lastSlideId).removeClass("current");
                this.navItems.eq(this.currentSlideId).addClass("current");
                if (this.settings.controlNavThumbs && this.settings.controlNavThumbsNavigation) {
                    var b = this.navItems.eq(this.currentSlideId).position().left;
                    var c = b - Math.abs(this._currThumbsX);
                    if (c > this._thumbsContainerWidth - this._outerThumbWidth * 2 - 1 - this._thumbsSpacing) {
                        if (!a) {
                            this._animateThumbs(-b + this._outerThumbWidth)
                        } else {
                            this._animateThumbs(-b - this._outerThumbWidth * 2 + this._thumbsContainerWidth + this._thumbsSpacing)
                        }
                    } else if (c < this._outerThumbWidth * 2 - 1) {
                        if (!a) {
                            this._animateThumbs(-b - this._outerThumbWidth * 2 + this._thumbsContainerWidth + this._thumbsSpacing)
                        } else {
                            this._animateThumbs(-b + this._outerThumbWidth)
                        }
                    }
                }
            }
        },
        _updateDirectionNav: function () {
            if (this.settings.directionNavEnabled) {
                if (this.settings.hideArrowOnLastSlide) {
                    if (this.currentSlideId == 0) {
                        this._arrowLeftBlocked = true;
                        this.arrowLeft.addClass("disabled");
                        if (this._arrowRightBlocked) {
                            this._arrowRightBlocked = false;
                            this.arrowRight.removeClass("disabled")
                        }
                    } else if (this.currentSlideId == this.numSlides - 1) {
                        this._arrowRightBlocked = true;
                        this.arrowRight.addClass("disabled");
                        if (this._arrowLeftBlocked) {
                            this._arrowLeftBlocked = false;
                            this.arrowLeft.removeClass("disabled")
                        }
                    } else {
                        if (this._arrowLeftBlocked) {
                            this._arrowLeftBlocked = false;
                            this.arrowLeft.removeClass("disabled")
                        } else if (this._arrowRightBlocked) {
                            this._arrowRightBlocked = false;
                            this.arrowRight.removeClass("disabled")
                        }
                    }
                }
            }
        },
        _resumeSlideshow: function (a) {
            if (this.slideshowEnabled) {
                var b = this;
                if (!this.slideshowTimer) {
                    this.slideshowTimer = setInterval(function () {
                        b.next()
                    }, this.settings.slideshowDelay)
                }
            }
        },
        _stopSlideshow: function (a) {
            if (this.slideshowTimer) {
                clearInterval(this.slideshowTimer);
                this.slideshowTimer = ""
            }
        },
        _preloadImage: function (b, c) {
            if (b) {
                if (b.preload) {
                    var d = this;
                    var e = new Image;
                    var f = a(e);
                    f.css("opacity", 0);
                    f.addClass("royalImage");
                    b.slide.prepend(f);
                    b.slide.prepend(this._preloader);
                    b.preload = false;
                    f.load(function () {
                        d._scaleImage(f, d.sliderWidth, d.sliderHeight);
                        f.animate({
                            opacity: 1
                        }, 300, function () {
                            b.slide.find(".royalPreloader").remove()
                        });
                        if (c) c.call()
                    }).attr("src", b.preloadURL)
                } else {
                    if (c) c.call()
                }
            } else {
                if (c) c.call()
            }
        },
        _recalculateThumbsScroller: function () {
            this._thumbsContainerWidth = parseInt(this._navigationContainer.width(), 10);
            this._minThumbsX = -(this._thumbsTotalWidth - this._thumbsContainerWidth);
            if (this._thumbsContainerWidth >= this._thumbsTotalWidth) {
                this._thumbsArrowRightBlocked = true;
                this._thumbsArrowLeftBlocked = true;
                this.thumbsArrowRight.addClass("disabled");
                this.thumbsArrowLeft.addClass("disabled");
                this._blockThumbnailsScroll = true;
                this._setThumbScrollerPosition(0)
            } else {
                this._blockThumbnailsScroll = false;
                var a = this.navItems.eq(this.currentSlideId).position().left;
                this._animateThumbs(-a + this._outerThumbWidth)
            }
        },
        _animateThumbs: function (a) {
            if (!this._blockThumbnailsScroll && a != this._currThumbsX) {
                if (a <= this._minThumbsX) {
                    a = this._minThumbsX;
                    this._thumbsArrowLeftBlocked = false;
                    this._thumbsArrowRightBlocked = true;
                    this.thumbsArrowRight.addClass("disabled");
                    this.thumbsArrowLeft.removeClass("disabled")
                } else if (a >= 0) {
                    a = 0;
                    this._thumbsArrowLeftBlocked = true;
                    this._thumbsArrowRightBlocked = false;
                    this.thumbsArrowLeft.addClass("disabled");
                    this.thumbsArrowRight.removeClass("disabled")
                } else {
                    if (this._thumbsArrowLeftBlocked) {
                        this._thumbsArrowLeftBlocked = false;
                        this.thumbsArrowLeft.removeClass("disabled")
                    }
                    if (this._thumbsArrowRightBlocked) {
                        this._thumbsArrowRightBlocked = false;
                        this.thumbsArrowRight.removeClass("disabled")
                    }
                }
                this._setThumbScrollerPosition(a);
                this._currThumbsX = a
            }
        },
        _setThumbScrollerPosition: function (a) {
            if (!this._useWebkitTransition) {
                this._thumbsNavContainer.animate({
                    left: a
                }, this.settings.controlNavThumbsSpeed, this.settings.controlNavThumbsEasing)
            } else {
                this._thumbsNavContainer.css({
                    "-webkit-transform": "translate3d(" + a + "px, 0, 0)"
                })
            }
        },
        _startSlider: function () {
            var b = this;
            this.slider.find(".royalLoadingScreen").remove();
            if (this.settings.controlNavEnabled) {
                this.navItems.bind("click", function (a) {
                    a.preventDefault();
                    if (!b._blockClickEvents) b._onNavItemClick(a)
                })
            }
            if (this.settings.directionNavEnabled) {
                this.arrowRight.click(function (a) {
                    a.preventDefault();
                    if (!b._arrowRightBlocked && !b._blockClickEvents) b.next()
                });
                this.arrowLeft.click(function (a) {
                    a.preventDefault();
                    if (!b._arrowLeftBlocked && !b._blockClickEvents) b.prev()
                })
            }
            if (this.settings.keyboardNavEnabled) {
                a(document).bind("keydown.rs", function (a) {
                    if (!b._blockClickEvents) {
                        if (a.keyCode === 37) {
                            b.prev()
                        } else if (a.keyCode === 39) {
                            b.next()
                        }
                    }
                })
            }
            this.wasSlideshowPlaying = true;
            this._onSlideAnimationComplete();
            this._dragContainer.bind(this._downEvent, function (a) {
                if (!b._dragBlocked) {
                    b._onDragStart(a)
                } else if (!this.hasTouch) {
                    a.preventDefault()
                }
            });
            if (this.slideshowEnabled && !this.settings.slideshowAutoStart) {
                this._stopSlideshow()
            }
            this.settings.allComplete.call(this)
        },
        _setGrabCursor: function () {
            this._dragContainer.removeClass("grabbing-cursor");
            this._dragContainer.addClass("grab-cursor")
        },
        _setGrabbingCursor: function () {
            this._dragContainer.removeClass("grab-cursor");
            this._dragContainer.addClass("grabbing-cursor")
        },
        _moveSlideRight: function (a) {
            if (this.currentSlideId < this.numSlides - 1) {
                this.goTo(this.currentSlideId + 1, false, false, a)
            } else {
                this.goTo(this.currentSlideId, false, false, a)
            }
        },
        _moveSlideLeft: function (a) {
            if (this.currentSlideId > 0) {
                this.goTo(this.currentSlideId - 1, false, false, a)
            } else {
                this.goTo(this.currentSlideId, false, false, a)
            }
        },
        _onNavItemClick: function (b) {
            this.goTo(a(b.currentTarget).index(), false, true)
        },
        _getWebkitTransformX: function () {
            var a = window.getComputedStyle(this._dragContainer.get(0), null).getPropertyValue("-webkit-transform");
            var b = a.replace(/^matrix\(/i, "").split(/, |\)$/g);
            return parseInt(b[4], 10)
        },
        _onDragStart: function (b) {
            if (!this._isDragging) {
                var c;
                if (this.hasTouch) {
                    this._lockYAxis = false;
                    var d = b.originalEvent.touches;
                    if (d && d.length > 0) {
                        c = d[0]
                    } else {
                        return false
                    }
                } else {
                    c = b;
                    b.preventDefault()
                }
                if (this.slideshowEnabled) {
                    if (this.slideshowTimer) {
                        this.wasSlideshowPlaying = true;
                        this._stopSlideshow()
                    } else {
                        this.wasSlideshowPlaying = false
                    }
                }
                this._setGrabbingCursor();
                this._isDragging = true;
                var e = this;
                if (this._useWebkitTransition) {
                    e._dragContainer.css({
                        "-webkit-transition-duration": "0ms",
                        "-webkit-transition-property": "none"
                    })
                }
                a(document).bind(this._moveEvent, function (a) {
                    e._onDragMove(a)
                });
                a(document).bind(this._upEvent, function (a) {
                    e._onDragRelease(a)
                });
                if (!this._useWebkitTransition) {
                    this._startPos = this._tx = parseInt(this._dragContainer.css("left"), 10)
                } else {
                    this._startPos = this._tx = this._getWebkitTransformX()
                }
                this._successfullyDragged = false;
                this._startMouseX = c.clientX;
                this._startMouseY = c.clientY
            }
            return false
        },
        _onDragMove: function (a) {
            var b;
            if (this.hasTouch) {
                if (this._lockYAxis) {
                    return false
                }
                var c = a.originalEvent.touches;
                if (c.length > 1) {
                    return false
                }
                b = c[0];
                if (Math.abs(b.clientY - this._startMouseY) > Math.abs(b.clientX - this._startMouseX) + 3) {
                    if (this.settings.lockAxis) {
                        this._lockYAxis = true
                    }
                    return false
                }
                a.preventDefault()
            } else {
                b = a;
                a.preventDefault()
            }
            this._lastDragPosition = this._currentDragPosition;
            var d = b.clientX - this._startMouseX;
            if (this._lastDragPosition != d) {
                this._currentDragPosition = d
            }
            if (d != 0) {
                if (this.currentSlideId == 0) {
                    if (d > 0) {
                        d = Math.sqrt(d) * 5
                    }
                } else if (this.currentSlideId == this.numSlides - 1) {
                    if (d < 0) {
                        d = -Math.sqrt(-d) * 5
                    }
                }
                if (!this._useWebkitTransition) {
                    this._dragContainer.css("left", this._tx + d)
                } else {
                    this._dragContainer.css({
                        "-webkit-transform": "translate3d(" + (this._tx + d) + "px, 0, 0)"
                    })
                }
            }
            return false
        },
        _onDragRelease: function (b) {
            if (this._isDragging) {
                this._isDragging = false;
                this._setGrabCursor();
                if (!this._useWebkitTransition) {
                    this.endPos = parseInt(this._dragContainer.css("left"), 10)
                } else {
                    this.endPos = this._getWebkitTransformX()
                }
                this.isdrag = false;
                a(document).unbind(this._moveEvent).unbind(this._upEvent);
                if (this.slideshowEnabled) {
                    if (this.wasSlideshowPlaying) {
                        if (!this._isHovering) {
                            this._resumeSlideshow()
                        }
                        this.wasSlideshowPlaying = false
                    }
                }
                if (this.endPos == this._startPos) {
                    this._successfullyDragged = false;
                    return
                } else {
                    this._successfullyDragged = true
                }
                if (this._startPos - this.settings.minSlideOffset > this.endPos) {
                    if (this._lastDragPosition < this._currentDragPosition) {
                        this.goTo(this.currentSlideId, false, false, true);
                        return false
                    }
                    this._moveSlideRight(true)
                } else if (this._startPos + this.settings.minSlideOffset < this.endPos) {
                    if (this._lastDragPosition > this._currentDragPosition) {
                        this.goTo(this.currentSlideId, false, false, true);
                        return false
                    }
                    this._moveSlideLeft(true)
                } else {
                    this.goTo(this.currentSlideId, false, false, true)
                }
            }
            return false
        },
        _onSlideAnimationComplete: function () {
            var a = this;
            if (this.slideshowEnabled) {
                if (this.wasSlideshowPlaying) {
                    if (!this._isHovering) {
                        this._resumeSlideshow()
                    }
                    this.wasSlideshowPlaying = false
                }
            }
            this._blockClickEvents = false;
            this._dragBlocked = false;
            if (this.settings.captionAnimationEnabled && this.lastSlideId != this.currentSlideId) {
                if (this.lastSlideId != -1) {
                    this.slidesArr[this.lastSlideId].caption.css("display", "none")
                }
                a._showCaption(a.currentSlideId)
            }
            this.isAnimating = false;
            this.settings.afterSlideChange.call(this)
        },
        _showCaption: function (b) {
            var c = this.slidesArr[b].caption;
            if (c && c.length > 0) {
                c.css("display", "block");
                var d = this;
                var e, f, g, h, i, j, k, l, m, n, o, p, q;
                var r = c.children();
                if (this._captionAnimateTimeouts.length > 0) {
                    for (var s = this._captionAnimateTimeouts.length - 1; s > -1; s--) {
                        clearTimeout(this._captionAnimateTimeouts.splice(s, 1))
                    }
                }
                if (this._captionAnimateProperties.length > 0) {
                    var t;
                    for (var u = this._captionAnimateProperties.length - 1; u > -1; u--) {
                        t = this._captionAnimateProperties[u];
                        if (t) {
                            if (!this._useWebkitTransition) {
                                if (t.running) {
                                    t.captionItem.stop(true, true)
                                } else {
                                    t.captionItem.css(t.css)
                                }
                            }
                        }
                        this._captionAnimateProperties.splice(u, 1)
                    }
                }
                for (var v = 0; v < r.length; v++) {
                    e = a(r[v]);
                    i = {};
                    f = false;
                    g = false;
                    j = "";
                    if (e.attr("data-show-effect") == undefined) {
                        k = this.settings.captionShowEffects
                    } else {
                        k = e.attr("data-show-effect").split(" ")
                    }
                    for (var w = 0; w < k.length; w++) {
                        if (f && g) {
                            break
                        }
                        h = k[w].toLowerCase();
                        if (!f && h == "fade") {
                            f = true;
                            i["opacity"] = 1
                        } else if (g) {
                            break
                        } else if (h == "movetop") {
                            j = "margin-top"
                        } else if (h == "moveleft") {
                            j = "margin-left"
                        } else if (h == "movebottom") {
                            j = "margin-bottom"
                        } else if (h == "moveright") {
                            j = "margin-right"
                        }
                        if (j != "") {
                            i["moveProp"] = j;
                            if (!d._useWebkitTransition) {
                                i["moveStartPos"] = parseInt(e.css(j), 10)
                            } else {
                                i["moveStartPos"] = 0
                            }
                            g = true
                        }
                    }
                    m = parseInt(e.attr("data-move-offset"), 10);
                    if (isNaN(m)) {
                        m = this.settings.captionMoveOffset
                    }
                    n = parseInt(e.attr("data-delay"), 10);
                    if (isNaN(n)) {
                        n = d.settings.captionShowDelay * v
                    }
                    o = parseInt(e.attr("data-speed"), 10);
                    if (isNaN(o)) {
                        o = d.settings.captionShowSpeed
                    }
                    p = e.attr("data-easing");
                    if (!p) {
                        p = d.settings.captionShowEasing
                    }
                    l = {};
                    if (g) {
                        q = i.moveProp;
                        if (q == "margin-right") {
                            q = "margin-left";
                            l[q] = i.moveStartPos + m
                        } else if (q == "margin-bottom") {
                            q = "margin-top";
                            l[q] = i.moveStartPos + m
                        } else {
                            l[q] = i.moveStartPos - m
                        }
                    }
                    if (!d._removeFadeAnimation && f) {
                        e.css("opacity", 0)
                    }
                    if (!d._useWebkitTransition) {
                        e.css("visibility", "hidden");
                        e.css(l);
                        if (g) {
                            l[q] = i.moveStartPos
                        }
                        if (!d._removeFadeAnimation && f) {
                            l.opacity = 1
                        }
                    } else {
                        var x = {};
                        if (g) {
                            x["-webkit-transition-duration"] = "0";
                            x["-webkit-transition-property"] = "none";
                            x["-webkit-transform"] = "translate3d(" + (isNaN(l["margin-left"]) ? 0 : l["margin-left"] + "px") + ", " + (isNaN(l["margin-top"]) ? 0 : l["margin-top"] + "px") + ",0)";
                            delete l["margin-left"];
                            delete l["margin-top"];
                            l["-webkit-transform"] = "translate3d(0,0,0)"
                        }
                        l.visibility = "visible";
                        l.opacity = 1;
                        if (!d._removeFadeAnimation && f) {
                            x["opacity"] = 0
                        }
                        x["visibility"] = "hidden";
                        e.css(x)
                    }
                    this._captionAnimateProperties.push({
                        captionItem: e,
                        css: l,
                        running: false
                    });
                    this._captionAnimateTimeouts.push(setTimeout(function (a, b, c, e, f, g, h) {
                        return function () {
                            d._captionAnimateProperties[f].running = true;
                            if (!d._useWebkitTransition) {
                                a.css("visibility", "visible").animate(b, c, e, function () {
                                    if (d._isIE8 && g) {
                                        a.get(0).style.removeAttribute("filter")
                                    }
                                    delete d._captionAnimateProperties[f]
                                })
                            } else {
                                a.css({
                                    "-webkit-transition-duration": c + "ms",
                                    "-webkit-transition-property": "opacity" + (h ? ", -webkit-transform" : ""),
                                    "-webkit-transition-timing-function": "ease-out"
                                });
                                a.css(b)
                            }
                        }
                    }(e, l, o, p, v, f, g), n))
                }
            }
        },
        _scaleImage: function (b, c, d) {
            var e = this.settings.imageScaleMode;
            var f = this.settings.imageAlignCenter;
            if (f || e == "fill" || e == "fit") {
                var g = false;

                function h() {
                    var a, g, h, i, j;
                    var k = new Image;
                    k.onload = function () {
                        var k = this.width;
                        var l = this.height;
                        var m = parseInt(b.css("borderWidth"), 10);
                        m = isNaN(m) ? 0 : m;
                        if (e == "fill" || e == "fit") {
                            a = c / k;
                            g = d / l;
                            if (e == "fill") {
                                h = a > g ? a : g
                            } else if (e == "fit") {
                                h = a < g ? a : g
                            } else {
                                h = 1
                            }
                            i = parseInt(k * h, 10) - m;
                            j = parseInt(l * h, 10) - m;
                            b.attr({
                                width: i,
                                height: j
                            }).css({
                                width: i,
                                height: j
                            })
                        } else {
                            i = k - m;
                            j = l - m;
                            b.attr("width", i).attr("height", j)
                        }
                        if (f) {
                            b.css({
                                "margin-left": Math.floor((c - i) / 2),
                                "margin-top": Math.floor((d - j) / 2)
                            })
                        }
                    };
                    k.src = b.attr("src")
                }
                b.removeAttr("height").removeAttr("width");
                if (!this._isImageLoaded(b.get(0))) {
                    a("<img />").load(function () {
                        h()
                    }).attr("src", b.attr("src"))
                } else {
                    h()
                }
            }
        },
        _isImageLoaded: function (a) {
            if (a) {
                if (!a.complete) {
                    return false
                }
                if (typeof a.naturalWidth != "undefined" && a.naturalWidth == 0) {
                    return false
                }
            } else {
                return false
            }
            return true
        }
    };
    a.fn.royalSlider = function (c) {
        return this.each(function () {
            var d = new b(a(this), c);
            a(this).data("royalSlider", d)
        })
    };
    a.fn.royalSlider.defaults = {
        lockAxis: true,
        preloadNearbyImages: true,
        imageScaleMode: "none",
        imageAlignCenter: false,
        keyboardNavEnabled: false,
        directionNavEnabled: true,
        directionNavAutoHide: false,
        hideArrowOnLastSlide: true,
        slideTransitionType: "move",
        slideTransitionSpeed: 400,
        slideTransitionEasing: "easeInOutSine",
        captionAnimationEnabled: true,
        captionShowEffects: ["fade", "moveleft"],
        captionMoveOffset: 20,
        captionShowSpeed: 400,
        captionShowEasing: "easeOutCubic",
        captionShowDelay: 200,
        controlNavEnabled: true,
        controlNavThumbs: false,
        controlNavThumbsNavigation: true,
        controlNavThumbsSpeed: 400,
        controlNavThumbsEasing: "easeInOutSine",
        slideshowEnabled: false,
        slideshowDelay: 5e3,
        slideshowPauseOnHover: true,
        slideshowAutoStart: true,
        welcomeScreenEnabled: false,
        welcomeScreenShowSpeed: 500,
        minSlideOffset: 20,
        disableTranslate3d: false,
        removeCaptionsOpacityInIE8: false,
        startSlideIndex: 0,
        slideSpacing: 0,
        blockLinksOnDrag: true,
        nonDraggableClassEnabled: true,
        dragUsingMouse: true,
        beforeSlideChange: function () {},
        afterSlideChange: function () {},
        beforeLoadStart: function () {},
        loadingComplete: function () {},
        allComplete: function () {}
    };
    a.fn.royalSlider.settings = {}
})(jQuery)