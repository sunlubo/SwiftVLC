//
//  Util.swift
//  SwiftVLC
//
//  Created by sunlubo on 2019/1/31.
//

/// Allows to "box" another value.
final class Box<T> {
  let value: T

  init(_ value: T) {
    self.value = value
  }
}
