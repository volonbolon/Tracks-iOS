//
//  VBMasterViewController.h
//  Tracks-iOS
//
//  Created by Ariel Rodriguez on 7/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VBDetailViewController;

#import <CoreData/CoreData.h>

@interface VBMasterViewController : UITableViewController <NSFetchedResultsControllerDelegate, UISearchBarDelegate, UISearchDisplayDelegate>

- (IBAction)insertNewObject:(id)sender;

@property (strong, nonatomic) VBDetailViewController *detailViewController;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSFetchedResultsController *searchFetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
