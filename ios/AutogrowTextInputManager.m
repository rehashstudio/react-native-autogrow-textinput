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
#else
#import "RCTTextView.h"
#endif

#import <objc/runtime.h>

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

@dynamic myEventDispatcher;

- (instancetype)my_initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher
{
    RCTTextView* textView = [self my_initWithEventDispatcher:eventDispatcher];
    textView.myEventDispatcher = eventDispatcher;
    return textView;
}

- (void)setMyEventDispatcher:(id)object {
     objc_setAssociatedObject(self, @selector(myEventDispatcher), object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)myEventDispatcher {
    return objc_getAssociatedObject(self, @selector(myEventDispatcher));
}

- (BOOL) my_textView:(RCTUITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    [self my_textView:textView shouldChangeTextInRange:range replacementText:text];

    NSDictionary* body = @{
        @"target": self.reactTag,
        @"rangeStart": @(range.location),
        @"rangeEnd": @(range.location + range.length),
        @"text": text,
    };

    [self.myEventDispatcher sendInputEventWithName:@"rangeChange" body:body];
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
    method_exchangeImplementations(class_getInstanceMethod(class, @selector(initWithEventDispatcher:)), class_getInstanceMethod(class, @selector(my_initWithEventDispatcher:)));
  });
}

@end
