//
//  FruitDetailModule.swift
//  Fruitful
//
//  Created by Peter Bloxidge on 22/05/2021.
//

import UIKit

class FruitDetailModule {
    
    static func build(fruit: Fruit) -> UIViewController {
        let view = FruitDetailViewController.instantiateFromStoryboard(name: "FruitDetail")
        let presenter = FruitDetailPresenterImpl(fruit: fruit)
        let interactor = FruitDetailInteractorImpl()
        let router = FruitDetailRouterImpl()
        
        view.presenter = presenter
        
        presenter.view = view
        presenter.router = router
        presenter.interactor = interactor
        
        router.viewController = view
        
        return view
    }
}
