//
//  VBMasterViewController.m
//  Tracks-iOS
//
//  Created by Ariel Rodriguez on 7/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VBMasterViewController.h"

#import "VBDetailViewController.h"

@interface VBMasterViewController ()
- (void)fetchedResultsController:(NSFetchedResultsController *)fetchedResultsController 
                   configureCell:(UITableViewCell *)theCell 
                     atIndexPath:(NSIndexPath *)theIndexPath;
- (UITableView *)tableViewForController:(NSFetchedResultsController *)controller;
- (NSFetchedResultsController *)fetchedResultsControllerForTableView:(UITableView *)tableView; 
- (NSFetchedResultsController *)freshFetchedResultsControllerWithSearch:(NSString *)searchString; 
- (void)filterContentForSearchText:(NSString *)searchText 
                             scope:(NSInteger)scope; 
@end

@implementation VBMasterViewController

@synthesize detailViewController = _detailViewController;
@synthesize fetchedResultsController = __fetchedResultsController;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize searchFetchedResultsController = __searchFetchedResultsController; 

#pragma mark - NSObject
- (id)initWithNibName:(NSString *)nibNameOrNil 
               bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil 
                         bundle:nibBundleOrNil];
  if (self) {
    [self setTitle:@"Tracks"]; 
  }
  return self;
}

#pragma mark - UIView
- (void)viewDidLoad {
  [super viewDidLoad];
  
  [[self navigationItem] setLeftBarButtonItem:[self editButtonItem]]; 
  
  UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
                                                                             target:self 
                                                                             action:@selector(insertNewObject:)];
  [[self navigationItem] setRightBarButtonItem:addButton];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - IBAction
- (IBAction)insertNewObject:(id)sender {
  // TODO: Implement new track sheet
}

#pragma mark - Table View
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return [[[self fetchedResultsControllerForTableView:tableView] sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  id <NSFetchedResultsSectionInfo> sectionInfo = [[[self fetchedResultsControllerForTableView:tableView] sections] objectAtIndex:section];
  return [sectionInfo numberOfObjects];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  }
  
  [self fetchedResultsController:[self fetchedResultsControllerForTableView:tableView]
                   configureCell:cell
                     atIndexPath:indexPath]; 
  
  return cell;
}

- (BOOL)tableView:(UITableView *)tableView 
canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}

- (BOOL)tableView:(UITableView *)tableView 
canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
  // The table view should not be re-orderable.
  return NO;
}

- (void)tableView:(UITableView *)tableView 
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
  if ( editingStyle == UITableViewCellEditingStyleDelete ) {
    NSManagedObjectContext *context = [[self fetchedResultsController] managedObjectContext];
    [context deleteObject:[[self fetchedResultsController] objectAtIndexPath:indexPath]];
    
    NSError *error = nil;
    if (![context save:&error]) {
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
      abort();
    }
  }   
}

- (void)tableView:(UITableView *)tableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (![self detailViewController]) {
    [self setDetailViewController:[[VBDetailViewController alloc] initWithNibName:@"VBDetailViewController" bundle:nil]];
  }
  NSManagedObject *object = [[self fetchedResultsControllerForTableView:tableView] objectAtIndexPath:indexPath];
  [[self detailViewController] setDetailItem:object];
  [[self navigationController] pushViewController:[self detailViewController]
                                         animated:YES];
}

- (NSString *)tableView:(UITableView *)tv 
titleForHeaderInSection:(NSInteger)section {
  NSFetchedResultsController *controller = [self fetchedResultsControllerForTableView:tv]; 
  NSString *sectionTitle = [[[controller sections] objectAtIndex:section] name];
  return sectionTitle;
}

#pragma mark - Fetched results controllers
// We have two controllers. One for the table, and one to populate the search results
- (NSFetchedResultsController *)fetchedResultsController {
  if (__fetchedResultsController != nil) {
    return __fetchedResultsController;
  }
  __fetchedResultsController = [self freshFetchedResultsControllerWithSearch:nil]; 
  return __fetchedResultsController; 
} 

- (NSFetchedResultsController *)searchFetchedResultsController {
  if (__searchFetchedResultsController != nil) {
    return __searchFetchedResultsController;
  }
  __searchFetchedResultsController = [self freshFetchedResultsControllerWithSearch:[[[self searchDisplayController] searchBar] text]]; 
  return __searchFetchedResultsController; 
} 

// This will produce a new fetched result controller when needed
- (NSFetchedResultsController *)freshFetchedResultsControllerWithSearch:(NSString *)searchString {
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"Track"
                                            inManagedObjectContext:self.managedObjectContext];
  [fetchRequest setEntity:entity];
  
  [fetchRequest setFetchBatchSize:20];
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"artistName" 
                                                                 ascending:YES];
  NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
  
  [fetchRequest setSortDescriptors:sortDescriptors];
  
  if ( [searchString length] > 0 ) {
    NSUInteger scope = [[[self searchDisplayController] searchBar] selectedScopeButtonIndex];
    NSPredicate *predicate = nil; 
    switch ( scope ) {
      case 0:
        predicate = [NSPredicate predicateWithFormat:@"artistName CONTAINS[cd] %@", searchString];
        break;
        
      case 1:
        predicate = [NSPredicate predicateWithFormat:@"trackName CONTAINS[cd] %@", searchString];
        break; 
    }
    
    [fetchRequest setPredicate:predicate]; 
  }
  
  [NSFetchedResultsController deleteCacheWithName:@"Master"];
  NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
                                                                                              managedObjectContext:self.managedObjectContext 
                                                                                                sectionNameKeyPath:@"artistName" 
                                                                                                         cacheName:@"Master"];
  [aFetchedResultsController setDelegate:self]; 
  
	NSError *error = nil;
	if (![aFetchedResultsController performFetch:&error]) {
    // Replace this implementation with code to handle the error appropriately.
    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    abort();
	}
  
  return aFetchedResultsController;
}

#pragma mark - NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
  [[self tableViewForController:controller] beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
  [[self tableViewForController:controller] endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type {
  UITableView *tableView = [self tableViewForController:controller];
  switch(type) {
    case NSFetchedResultsChangeInsert:
      [tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
               withRowAnimation:UITableViewRowAnimationFade];
      break;
      
    case NSFetchedResultsChangeDelete:
      [tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
               withRowAnimation:UITableViewRowAnimationFade];
      break;
  }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath 
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
  UITableView *tableView = [self tableViewForController:controller];
  
  switch(type) {
    case NSFetchedResultsChangeInsert:
      [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                       withRowAnimation:UITableViewRowAnimationFade];
      break;
      
    case NSFetchedResultsChangeDelete:
      [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
                       withRowAnimation:UITableViewRowAnimationFade];
      break;
      
    case NSFetchedResultsChangeUpdate:
      [self fetchedResultsController:[self fetchedResultsControllerForTableView:tableView]
                       configureCell:[tableView cellForRowAtIndexPath:indexPath]
                         atIndexPath:indexPath];
      break;
      
    case NSFetchedResultsChangeMove:
      [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                       withRowAnimation:UITableViewRowAnimationFade];
      [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                       withRowAnimation:UITableViewRowAnimationFade];
      break;
  }
}

#pragma mark - Convinience method to cofigure cell
- (void)fetchedResultsController:(NSFetchedResultsController *)fetchedResultsController 
                   configureCell:(UITableViewCell *)cell 
                     atIndexPath:(NSIndexPath *)indexPath {
  
  NSManagedObject *object = [fetchedResultsController objectAtIndexPath:indexPath];
  [[cell textLabel] setText:[object valueForKey:@"trackName"]]; 
}

#pragma mark - Search Display Controller 
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller 
shouldReloadTableForSearchString:(NSString *)searchString {
  [self filterContentForSearchText:searchString
                             scope:[[controller searchBar] selectedScopeButtonIndex]]; 
  return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller 
shouldReloadTableForSearchScope:(NSInteger)searchOption {
  [self filterContentForSearchText:[[controller searchBar] text]
                             scope:searchOption]; 
  return YES; 
}

- (void)searchDisplayController:(UISearchDisplayController *)controller
willUnloadSearchResultsTableView:(UITableView *)tableView {
  [[self searchFetchedResultsController] setDelegate:nil];
  [self setSearchFetchedResultsController:nil]; 
}

- (void)filterContentForSearchText:(NSString *)searchText 
                             scope:(NSInteger)scope {
  [[self searchFetchedResultsController] setDelegate:nil];
  [self setSearchFetchedResultsController:nil];
}

#pragma mark - Convenience methods to manage controllers and table views
- (NSFetchedResultsController *)fetchedResultsControllerForTableView:(UITableView *)tv {
  if ( [tv isEqual:[self tableView]] ) {
    return [self fetchedResultsController]; 
  }
  return [self searchFetchedResultsController];  
}

- (UITableView *)tableViewForController:(NSFetchedResultsController *)controller {
  if ( [controller isEqual:[self fetchedResultsController]] ) {
    return [self tableView]; 
  }
  return [[self searchDisplayController] searchResultsTableView];
}

@end
