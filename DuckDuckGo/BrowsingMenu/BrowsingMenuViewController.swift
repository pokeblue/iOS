//
//  BrowsingMenuViewController.swift
//  DuckDuckGo
//
//  Copyright © 2021 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit

protocol BrowsingMenu {
    
    func setMenuEntires(_ entries: [BrowsingMenuEntry])
}

enum BrowsingMenuEntry {
    
    case regular(name: String, image: UIImage, action: () -> Void)
    case separator
}

class BrowsingMenuViewController: UIViewController, BrowsingMenu {
    
    typealias DismissHandler = () -> Void
    
    @IBOutlet weak var horizontalContainer: UIStackView!
    @IBOutlet weak var separatorHeight: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    
    weak var background: UIView?
    private var dismiss: DismissHandler?
    
    private var headerButtons: [BrowsingMenuButton] = []
    private var headerEntries: [BrowsingMenuEntry] = []
    
    private var menuEntries: [BrowsingMenuEntry] = [] {
        didSet {
            recalculateLayout()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureHeader()
        configureTableView()
        configureShadow()
        
        applyTheme(ThemeManager.shared.currentTheme)
    }
    
    private func configureHeader() {
        guard headerButtons.isEmpty else { return }
        
        if headerButtons.isEmpty {
            var previousButton: UIView?
            for _ in 1...4 {
                let button = BrowsingMenuButton.loadFromXib()
                horizontalContainer.addArrangedSubview(button)
                button.heightAnchor.constraint(equalTo: horizontalContainer.heightAnchor, multiplier: 1.0).isActive = true
                previousButton?.widthAnchor.constraint(equalTo: button.widthAnchor, multiplier: 1.0).isActive = true
                
                headerButtons.append(button)
                previousButton = button
            }
        }
    }
    
    private func configureTableView() {
        
        tableView.register(UINib(nibName: "BrowsingMenuEntryViewCell", bundle: nil),
                           forCellReuseIdentifier: "BrowsingMenuEntryViewCell")
        tableView.register(UINib(nibName: "BrowsingMenuSeparatorViewCell", bundle: nil),
                           forCellReuseIdentifier: "BrowsingMenuSeparatorViewCell")
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func configureShadow() {
        view.clipsToBounds = false
        
        view.layer.cornerRadius = 10
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.12
        view.layer.shadowRadius = 3
    }
    
    func attachTo(_ targetView: UIView, onDismiss: @escaping DismissHandler) {
        assert(background == nil, "\(#file) - view has been already attached")
        
        dismiss = onDismiss
        
        let background = UIView()
        background.backgroundColor = .clear
        targetView.addSubview(background)
        background.frame = targetView.bounds
        self.background = background
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        background.addGestureRecognizer(tapGesture)
        
        targetView.addSubview(view)
        
        recalculateLayout()
    }
    
    @objc func backgroundTapped() {
        dismiss?()
    }
    
    func detachFrom(_ targetView: UIView) {
        background?.removeFromSuperview()
        background = nil
        view.removeFromSuperview()
        
        dismiss = nil
    }
    
    private func recalculateLayout() {
        guard isViewLoaded else { return }
        
        tableView.reloadData()
        tableViewHeight.constant = tableView.contentSize.height
    }
    
    func setHeaderEntires(_ entries: [BrowsingMenuEntry]) {
        configureHeader()
        guard entries.count == headerButtons.count else {
            fatalError("Mismatched number of entries in \(#file):\(#function) expected: \(headerButtons.count) but found \(entries.count)")
        }
        
        for (entry, view) in zip(entries, headerButtons) {
            guard case .regular(let name, let image, let action) = entry else {
                fatalError("Regular entry not found")
            }
            
            view.configure(with: image, label: name, action: action)
        }
        
        headerEntries = entries
    }
    
    func setMenuEntires(_ entries: [BrowsingMenuEntry]) {
        menuEntries = entries
    }
}

extension BrowsingMenuViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch menuEntries[indexPath.row] {
        case .regular(_, _, let action):
            action()
        case .separator:
            break
        }
    }
}

// swiftlint:disable line_length
extension BrowsingMenuViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuEntries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let theme = ThemeManager.shared.currentTheme
        
        switch menuEntries[indexPath.row] {
        case .regular(let name, let image, _):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "BrowsingMenuEntryViewCell", for: indexPath) as? BrowsingMenuEntryViewCell else {
                fatalError()
            }
            
            cell.configure(image: image, label: name, theme: theme)
            return cell
        case .separator:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "BrowsingMenuSeparatorViewCell", for: indexPath) as? BrowsingMenuSeparatorViewCell else {
                fatalError()
            }
            
            cell.separator.backgroundColor = theme.browsingMenuBackgroundColor
            return cell
        }
    }
}
// swiftlint:enable line_length

extension BrowsingMenuViewController: Themable {
    
    func decorate(with theme: Theme) {
        
        for headerButton in headerButtons {
            headerButton.image.tintColor = theme.browsingMenuTopIconsColor
            headerButton.label.textColor = theme.browsingMenuTextColor
        }
        
        horizontalContainer.backgroundColor = theme.browsingMenuBackgroundColor
        tableView.backgroundColor = theme.browsingMenuBackgroundColor
        
        tableView.reloadData()
    }
}