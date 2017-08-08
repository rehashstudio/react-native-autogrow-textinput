//
//  AutogrowTextInputManager.m
//  example
//
//  Created by Artal Druk on 05/05/2016.
//  Copyright © 2016 Wix.com. All rights reserved.
//

#import "AutogrowTextInputManager.h"

#if __has_include(<React/RCTTextView.h>)
#import <React/RCTTextView.h>
#import <React/RCTTextViewManager.h>
#import <React/RCTTextSelection.h>
#else
#import "RCTTextView.h"
#import "RCTTextViewManager.h"
#import "RCTTextSelection.h"
#endif

#import <objc/runtime.h>

@implementation RCTTextViewManager(RangeChange)

RCT_EXPORT_VIEW_PROPERTY(onRangeChange, RCTBubblingEventBlock);

@end

@interface RCTTextView(RangeChange)
@property(nonatomic, copy) RCTBubblingEventBlock onRangeChange;
@property(assign) int isInTextDidChange;
@property(nonatomic, copy) UITextView* myTextView;
@end

@implementation RCTTextView(RangeChange)

- (void)setOnRangeChange:(RCTBubblingEventBlock)object {
    objc_setAssociatedObject(self, @selector(onRangeChange), object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (RCTBubblingEventBlock)onRangeChange {
    return objc_getAssociatedObject(self, @selector(onRangeChange));
}

- (void)setMyTextView:(UITextView*)object {
    objc_setAssociatedObject(self, @selector(myTextView), object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UITextView*)myTextView {
    return objc_getAssociatedObject(self, @selector(myTextView));
}

- (void)setIsInTextDidChange:(int)didChange {
    objc_setAssociatedObject(self, @selector(isInTextDidChange), @(didChange), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (int)isInTextDidChange {
    return [objc_getAssociatedObject(self, @selector(isInTextDidChange)) intValue];
}

- (BOOL) my_textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    self.myTextView = textView;

    BOOL res = [self my_textView:textView shouldChangeTextInRange:range replacementText:text];
    
    if (self.isInTextDidChange > 0) {
        return res;
    }
    
    NSRange selectedRange = textView.selectedRange;
    
    NSDictionary* body = @{
                           @"target": self.reactTag,
                           @"replaceRange": @{
                                   @"start": @(range.location),
                                   @"end": @(range.location + range.length),
                                   },
                           @"selectedRange": @{
                                   @"start": @(selectedRange.location),
                                   @"end": @(selectedRange.location + selectedRange.length),
                                   },
                           @"text": text,
                           };
    
    if (self.onRangeChange) {
        self.onRangeChange(@{@"src": body});
    }

    return res;
}

- (void) my_textViewDidChange:(UITextView *)textView
{
    self.myTextView = textView;
    self.isInTextDidChange += 1;
    [self my_textViewDidChange:textView];
    self.isInTextDidChange -= 1;
}

- (void)my_setSelection:(RCTTextSelection *)selection
{
    if (!selection) {
        return;
    }
    
    UITextView* tv = self.myTextView;
    
    UITextPosition *start = [tv positionFromPosition:tv.beginningOfDocument offset:selection.start];
    UITextPosition *end = [tv positionFromPosition:tv.beginningOfDocument offset:selection.end];
    
    if (start && end) {
        [self my_setSelection:selection];
    }
}

@end

@implementation UITextView(OnRangeChange)

@end

@interface RCTTextView(SetTextNotifyChange)
@end

@implementation RCTTextView(SetTextNotifyChange)
- (void)my_setText:(NSString *)text
{
  [self my_setText:text];
  
  UITextView *textView = [self valueForKey:@"_textView"];
  if (textView != nil && [self respondsToSelector:@selector(textViewDidChange:)])
  {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self textViewDidChange:textView];
    });
  }
}

@end

@implementation AutoGrowTextInputManager

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(setupNotifyChangeOnSetText)
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    Class class = [RCTTextView class];
    method_exchangeImplementations(class_getInstanceMethod(class, @selector(setText:)), class_getInstanceMethod(class, @selector(my_setText:)));
    method_exchangeImplementations(class_getInstanceMethod(class, @selector(textView:shouldChangeTextInRange:replacementText:)), class_getInstanceMethod(class, @selector(my_textView:shouldChangeTextInRange:replacementText:)));
      method_exchangeImplementations(class_getInstanceMethod(class, @selector(setSelection:)), class_getInstanceMethod(class, @selector(my_setSelection:)));
  });
}

@end
