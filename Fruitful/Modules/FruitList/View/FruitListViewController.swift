//
//  FruitListViewController.swift
//  Fruitful
//
//  Created by Peter Bloxidge on 22/05/2021.
//

import UIKit

class FruitListViewController: UIViewController {
    
    struct Constants {
        static let cellSpacing: CGFloat = 16
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var noResultsContainer: UIStackView!
    @IBOutlet weak var noResultsLabel: UILabel!
    @IBOutlet weak var reloadButton: RoundedBorderButton!
    
    var presenter: FruitListPresenter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleViews()
        setUpCollectionView()
        
        presenter.attachToView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        presenter.reload(showLoading: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        AnalyticsServiceImpl.shared.track(screenEvent: .displayed(.fruitList))
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        styleViews()
    }
    
    private func styleViews() {
        titleLabel.font = .titleStyle()
        noResultsLabel.font = .bodyStyle(size: 16)
        reloadButton.titleLabel?.font = .bodyStyle(size: 18)
    }
    
    private func setUpCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.addRefreshControl { [weak self] in
            guard let self = self else { return }
            if !self.collectionView.isDragging {
                self.refresh()
            }
        }
    }
    
    private func refresh() {
        presenter.reload(showLoading: false)
            .ensure { [weak self] in
                self?.collectionView.endRefreshing()
            }.cauterize()
    }
    
    @IBAction func reloadPressed() {
        presenter.reload(showLoading: true)
    }
    
    private func presentErrorAlert(message: String) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let retryAction = UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.presenter.reload(showLoading: true)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(retryAction)
        present(alertController, animated: true)
    }
}

extension FruitListViewController: FruitListView {
    
    func updateView(state: FruitListViewState) {
        switch state {
        case .initial:
            activityIndicator.stopAnimating()
            collectionView.isHidden = true
            noResultsContainer.isHidden = true
            
        case .loading:
            activityIndicator.startAnimating()
            collectionView.isHidden = true
            noResultsContainer.isHidden = true
            
        case .doneResults:
            activityIndicator.stopAnimating()
            collectionView.reloadData()
            collectionView.isHidden = false
            noResultsContainer.isHidden = true
            
        case .doneEmpty:
            activityIndicator.stopAnimating()
            collectionView.reloadData()
            collectionView.isHidden = true
            noResultsContainer.isHidden = false
            
        case .error:
            activityIndicator.stopAnimating()
            collectionView.isHidden = true
            presentErrorAlert(message: "Oops, something went wrong. Please try again.")
        }
    }
}

extension FruitListViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return presenter.getFruitCount() ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FruitListCollectionViewCell",
                                                      for: indexPath) as! FruitListCollectionViewCell
        let fruit = presenter.getFruit(at: indexPath.item)
        cell.title = fruit?.type
        return cell
    }
}

extension FruitListViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let selectedFruit = presenter.getFruit(at: indexPath.item) {
            presenter.didSelect(fruit: selectedFruit)
        }
    }
}

extension FruitListViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellsPerRow = CGFloat(getCellsPerRow(portrait: collectionView.bounds.width < collectionView.bounds.height,
                                                 isPad: UIDevice.current.userInterfaceIdiom == .pad))
        let contentWidth = collectionView.bounds.width - (Constants.cellSpacing * 2)
        let width = (contentWidth - (Constants.cellSpacing * (cellsPerRow - 1))) / cellsPerRow
        return CGSize(width: width, height: width * 0.75)
    }
    
    private func getCellsPerRow(portrait: Bool, isPad: Bool) -> Int {
        switch (portrait, isPad) {
        case (true, false):
            return 2
        case (false, false),
             (true, true):
            return 4
        case (false, true):
            return 6
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.cellSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.cellSpacing
    }
}

extension FruitListViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.isRefreshing {
            refresh()
        }
    }
}

