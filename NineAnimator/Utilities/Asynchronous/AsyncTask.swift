//
//  This file is part of the NineAnimator project.
//
//  Copyright © 2018-2019 Marcus Zhou. All rights reserved.
//
//  NineAnimator is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  NineAnimator is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with NineAnimator.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation

/// Representing an asynchronized task that can be cancelled
protocol NineAnimatorAsyncTask: AnyObject {
    func cancel()
}

/// A container class used to hold strong references to the
/// contained NineAnimatorAsyncTask and cancel them when
/// needed.
class AsyncTaskContainer: NineAnimatorAsyncTask {
    private var tasks: [NineAnimatorAsyncTask]
    
    init() { tasks = [] }
    
    func add(_ task: NineAnimatorAsyncTask?) {
        if let task = task {
            tasks.append(task)
        }
    }
    
    func cancel() {
        for task in tasks {
            task.cancel()
        }
    }
    
    static func += (left: AsyncTaskContainer, right: NineAnimatorAsyncTask?) {
        left.add(right)
    }
    
    deinit {
        cancel()
        tasks = []
    }
}
