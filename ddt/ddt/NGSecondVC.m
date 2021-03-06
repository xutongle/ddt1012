//
//  NGSecondVC.m
//  ddt
//
//  Created by gener on 15/10/13.
//  Copyright (c) 2015年 Light. All rights reserved.
//
//NGVCTypeId_1  同行Id
//NGVCTypeId_2  搜索同行Id
//NGVCTypeId_3  附近同行
//NGVCTypeId_4  接单
//NGVCTypeId_5  求职
//NGVCTypeId_6  招聘

#import "NGSecondVC.h"
#import "NGSearchBar.h"
#import "NGPopListView.h"
#import "NGTongHDetailVC.h"
#import "NGJieDanDetailVC.h"
#import "NGZPPersonInfoVC.h"

#import "NGZhaoPinDetailVC.h"

#import "NGSecondListCell.h"
#import "DTCompanyListCell.h"
#import "NGJieDanListCell.h"
#import "NGZhaoPinCell.h"

static NSString * showTongHangVcID  = @"showTongHangVcID";
static NSString * showCompanyVcID   = @"showCompanyVcID";
static NSString * showJieDanVcID    = @"showJieDanVcID";
static NSString * showQinZhiVcID    = @"showQinZhiVcID";
static NSString * showZhaoPinVcID   = @"showZhaoPinVcID";

static NSString * NGSecondListCellReuseId = @"NGSecondListCellReuseId";
static NSString * NGCompanyListCellReuseId = @"NGCompanyListCellReuseId";
static NSString * JieDanCellReuseId = @"JieDanCellReuseId";

@interface NGSecondVC ()<NGSearchBarDelegate,NGPopListDelegate,UITableViewDataSource,UITableViewDelegate>
{
    //pop view相关
    NGPopListView *popView;
    NSArray * _common_pop_btnTitleArr; //同行-选择按钮的默认标题
    NSArray * _common_pop_btnListArr;//列表数据
    
    //tableview相关
    UITableView     * _tableView;
    NSMutableArray  * _common_list_dataSource;//数据源
    NSArray         * _common_cellId_arr;//复用cell ID
    NSString        * _common_list_cellReuseId;//当前复用cellID
    NSString        * _common_list_cellClassStr;//当前cell class
    NSDictionary    * _common_list_request_parm;
    NSString        * _common_list_url;
    
    UIBarButtonItem *rightitem ;
    
    CGSize cellMaxFitSize;
    UIFont *cellFitfont;
    NSInteger _pageNum;//请求的页数
    NSInteger _selectRowIndex;
    
    //搜搜
    NGSearchBar *_searchBar;
    BOOL _isfirstAppear;
    
    //同行详情
    BOOL _isLoved;//是否收藏
}

//各列表表头参数
//同行参数
@property(nonatomic,copy)NSString * selectedSex;//选择性别，默认为空

//接单
@property(nonatomic,copy)NSString * selectedTime;//选择时间

//我要招聘
@property(nonatomic,copy)NSString * selectedZhiWei;//选择职位
@property(nonatomic,copy)NSString * selectedJingYan;//选择经验

@end

#import "LoginViewController.h"

@implementation NGSecondVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initData];
    [self initSubviews];

//    [self loadMoreData];
    [_tableView.header beginRefreshing];
    if (self.vcType == NGVCTypeId_5) {
        self.navigationItem.rightBarButtonItem= nil;
    }
}

-(void)awakeFromNib
{
    UIBarButtonItem *_item = [[UIBarButtonItem alloc]init];
    _item.title = @"";
    self.navigationItem.backBarButtonItem = _item;
    
    UIButton *rightbtn = [UIButton buttonWithType:UIButtonTypeCustom];
    rightbtn.frame = CGRectMake(0, 0, 100, 30);
    [rightbtn setTitle:@"关闭自己位置" forState:UIControlStateNormal];
    rightbtn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    rightbtn.titleLabel.textAlignment = NSTextAlignmentRight;
    [rightbtn setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, -20)];
    rightbtn.selected = NO;
    [rightbtn addTarget:self action:@selector(closedLocation:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:rightbtn];
}

-(void)closedLocation :(UIButton*)btn
{
    btn.selected = !btn.selected;
    [btn setTitle:btn.selected ? @"关闭自己位置":@"公开自己位置" forState:UIControlStateNormal];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    [_tableView.header beginRefreshing];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [popView disappear];
}

-(void)goback:(UIButton *)btn
{
    [popView disappear];
    [self.navigationController popViewControllerAnimated:YES];
}


-(void)initData
{
    _isfirstAppear = YES;
    _pageNum = 1;
    
    //pop
    NSInteger _index = self.tabBarController.selectedIndex;
    if (_index == 1) {
        self.vcType = NGVCTypeId_1;
    }
    
    //btn title
    NSArray *_sexArr = [DTComDataManger getData_sex];//性别
    NSArray *_areaArr = [NGXMLReader getCurrentLocationAreas];//区域
    NSArray *_typeArr = [NGXMLReader getBaseTypeData];//基本业务类型

    switch (self.vcType) {
        case NGVCTypeId_1:
        case NGVCTypeId_2:
        case NGVCTypeId_3:
        {//同行
            self.navigationItem.rightBarButtonItem = nil;
            NSArray *_btnTitleArr1 = @[@"服务区域",@"业务类型",@"性别"];
            _common_pop_btnTitleArr = _btnTitleArr1;
            _common_pop_btnListArr  = @[_areaArr,_typeArr,_sexArr];
            _common_list_url =self.vcType < NGVCTypeId_3? NSLocalizedString(@"url_tongh_fj_list", @""):NSLocalizedString(@"url_tongh_fj_list", @"");//url_tongh_list
            _selectedArea = self.selectedArea?self.selectedArea: @"";
            _selectedType = self.selectedType ?self.selectedType: @"";
            _selectedSex = @"";
            _isLoved = NO;
            
            [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(refreshDataForNoti) name:@"NOTI_LOVE_ORNOT_ACTION" object:nil];
            
        } break;
    
        case NGVCTypeId_4:
        {//接单
            NSArray *tmp = @[@"服务区域",@"业务类型",@"时间"];
            NSArray *time = [DTComDataManger getData_jiedanTime];
            _common_pop_btnTitleArr = tmp;
            _common_pop_btnListArr  = @[_areaArr,_typeArr,time];
            _common_list_url  =NSLocalizedString(@"url_jiedan", @"");
            _selectedArea = @"";
            _selectedType = @"";
            _selectedTime = @"";
        } break;
            
        case NGVCTypeId_5:
        {//招聘
            NSArray *tmp = @[@"区域",@"类型",@"工资",@"职位",@"经验"];
            NSArray *_a1 = [DTComDataManger getData_qwxz];
            NSArray *_a2 = [DTComDataManger getData_gwlx];
            NSArray *_a3 = [DTComDataManger getData_gzjy];
            _common_pop_btnTitleArr = tmp;
            _common_pop_btnListArr  = @[_areaArr,_typeArr,_a1,_a2,_a3];
            _common_list_url  =NSLocalizedString(@"url_qiuzhi", @"");
            _selectedArea = @"";
            _selectedType = @"";
            _selectedSex = @"";
            _selectedJingYan = @"";
            _selectedZhiWei = @"";
        } break;

        default: break;
    }
    
    
    //....此处获取tableview的数据源
    //...test   tableview
    _common_list_dataSource = [[NSMutableArray alloc]init];
    _common_cellId_arr = @[NGSecondListCellReuseId,NGSecondListCellReuseId,NGSecondListCellReuseId,JieDanCellReuseId,@"NGZhaoPinCellId"];
    _common_list_cellReuseId = [_common_cellId_arr objectAtIndex:self.vcType - 1];
    
    cellMaxFitSize = CGSizeMake(CurrentScreenWidth -130, 999);
    cellFitfont = [UIFont systemFontOfSize:14];
    
}

-(void)refreshDataForNoti
{
    _pageNum = 1;
    [self loadMoreData];
}


//请求参数初始化
-(void)initParams
{
    NSString *tel = [[MySharetools shared]getPhoneNumber];
    switch (self.vcType) {
        case NGVCTypeId_3:
        case NGVCTypeId_2:
        case NGVCTypeId_1://,@"121.68571511,31.19302052"-同行
        {
            //tel,@"username",tel,@"mobile",
            NSString * _lat = [[NSUserDefaults standardUserDefaults]objectForKey:CURRENT_LOCATION_LAT]?[[NSUserDefaults standardUserDefaults]objectForKey:CURRENT_LOCATION_LAT]:@"31.19302052";
            NSString *_log = [[NSUserDefaults standardUserDefaults]objectForKey:CURRENT_LOCATION_LOG]?[[NSUserDefaults standardUserDefaults]objectForKey:CURRENT_LOCATION_LOG] :@"121.68571511";
            
            _common_list_request_parm = [NSDictionary dictionaryWithObjectsAndKeys: _selectedArea?_selectedArea:@"",@"quyu",_selectedType?_selectedType:@"",@"yewu",@"10",@"psize",@(_pageNum),@"pnum",_searchBar.text.length > 0?_searchBar.text:@"",@"word",_selectedSex?_selectedSex:@"",@"xb",_log,@"mapx",_lat,@"mapy",nil];
        }break;
            
        case NGVCTypeId_4://搜单子
            _common_list_request_parm = [NSDictionary dictionaryWithObjectsAndKeys:tel,@"username",tel,@"mobile", _selectedArea?_selectedArea:@"",@"quyu",_selectedType?_selectedType:@"",@"yewu",_searchBar.text.length > 0?_searchBar.text:@"",@"word",_selectedTime,@"time",@"10",@"psize",@(_pageNum),@"pnum",nil];
            break;
        case NGVCTypeId_5://招聘
            _common_list_request_parm = [NSDictionary dictionaryWithObjectsAndKeys:tel,@"username", _selectedArea?_selectedArea:@"",@"quyu",_selectedType?_selectedType:@"",@"yewu",_searchBar.text.length > 0?_searchBar.text:@"",@"word",_selectedSex,@"money",_selectedJingYan,@"old",_selectedZhiWei,@"work",@"10",@"psize",@(_pageNum),@"pnum",nil]; break;
        default:break;
    }
}

#pragma mark- init subviews
-(void)initSubviews
{
    NSArray *_titleArr = @[@"同行名片",@"同行名片",@"附近同行",@"我要接单",@"我要求职",@"我要招聘"];
    self.title = [_titleArr objectAtIndex:self.vcType - 1];
    
    popView = [[NGPopListView alloc]initWithFrame:CGRectMake(0, 0, CurrentScreenWidth, 40) withDelegate:self withSuperView:self.view];
    [self.view addSubview:popView];
    
    _searchBar = [[NGSearchBar alloc]initWithFrame:CGRectMake(2, popView.frame.origin.y + popView.frame.size.height + 1, CurrentScreenWidth -4 , 30)];
    _searchBar.delegate  =self;
    _searchBar.placeholder = @"请输入搜索关键字";
    if (self.searchKey) {
        _searchBar.text = self.searchKey;
    }
    [self.view addSubview:_searchBar];
    
    NSInteger _heightValue = _vcType > 1 ? CurrentScreenHeight -64 -40-30 -2 : CurrentScreenHeight -64-44 -40-30 -2;
    _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, _searchBar.frame.origin.y + _searchBar.frame.size.height, CurrentScreenWidth,_heightValue ) style:UITableViewStylePlain];
    _tableView.delegate =self;
    _tableView.dataSource  =self;
    [self.view  addSubview:_tableView];
    [_tableView setContentInset:UIEdgeInsetsMake(0, 0, 20, 0)];
    _tableView.tableFooterView = [[UIView alloc]init];
    
    switch (self.vcType) {
        case NGVCTypeId_1:
        case NGVCTypeId_2:
        case NGVCTypeId_3:
            [_tableView registerNib:[UINib nibWithNibName:@"NGSecondListCell" bundle:nil] forCellReuseIdentifier:NGSecondListCellReuseId];break;
        case NGVCTypeId_4:
            self.navigationItem.rightBarButtonItem  = nil;
            [_tableView registerNib:[UINib nibWithNibName:@"NGJieDanListCell" bundle:nil] forCellReuseIdentifier:JieDanCellReuseId];break;
        case NGVCTypeId_5:
            [_tableView registerNib:[UINib nibWithNibName:@"NGZhaoPinCell" bundle:nil] forCellReuseIdentifier:@"NGZhaoPinCellId"];break;
        default:break;
    }

    //添加下拉刷新
    __weak __typeof(self) weakSelf = self;
    _tableView.header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        _pageNum = 1;
        [weakSelf loadMoreData];
    }];
//    _tableView.footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
//        [_tableView.footer resetNoMoreData];
//        [weakSelf loadMoreData];
//    }];
   
    if (self.vcType == NGVCTypeId_4) {
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
}

#pragma mark --加载数据
-(void)loadMoreData
{
    NetIsReachable;
    if (_pageNum == NSNotFound) {
        NSLog(@"...page error ");return;
    }
    NSLog(@"##############: %ld",_pageNum);
    
    [self initParams];
    NSDictionary *_d = [MySharetools getParmsForPostWith:_common_list_request_parm withToken:YES];
    
    RequestTaskHandle *task = [RequestTaskHandle taskWithUrl:_common_list_url parms:_d andSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        _pageNum ==1?({[_tableView.header endRefreshing];}):([_tableView.footer endRefreshing]);
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            if ([[responseObject objectForKey:@"result"]integerValue] ==0 ) {
                if (_pageNum ==1) { [_common_list_dataSource removeAllObjects];}
                NSArray *dataarr = [responseObject objectForKey:@"data"];
                if (dataarr) {
                    //...没有数据了，不能在刷新加载了
                    if (dataarr.count < 10)
                    {
                        _pageNum = NSNotFound;
                        [_tableView.footer endRefreshingWithNoMoreData];
                    }
                    
                    [_common_list_dataSource addObjectsFromArray:dataarr];
                    [_tableView reloadData];
                }
            }
            else if ([[responseObject objectForKey:@"result"]integerValue] ==2)
            {
                if (_pageNum ==1) { [_common_list_dataSource removeAllObjects];}
                [_tableView reloadData];
            }
            else
            {
//                [SVProgressHUD showInfoWithStatus:@"暂无数据"];
                _pageNum = NSNotFound;
                [_tableView.footer endRefreshingWithNoMoreData];
            }
        }
    } faileBlock:^(AFHTTPRequestOperation *operation, NSError *error) {
        [SVProgressHUD showInfoWithStatus:@"请求服务器失败"];
        _pageNum ==1?({[_tableView.header endRefreshing];}):([_tableView.footer endRefreshing]);
    }];
    
    [HttpRequestManager doPostOperationWithTask:task];
}


#pragma mark - NGPopListDelegate
-(NSInteger)numberOfSectionInPopView:(NGPopListView *)poplistview
{
    return _common_pop_btnTitleArr?_common_pop_btnTitleArr.count:0;
}
-(NSString *)titleOfSectionInPopView:(NGPopListView *)poplistview atIndex:(NSInteger)index
{
    return [_common_pop_btnTitleArr objectAtIndex:index];
}
//第一个列表显示的数据源,NSArray类型
-(NSArray*)dataSourceOfPoplistviewWithIndex:(NSInteger)index
{
    return [_common_pop_btnListArr objectAtIndex:index];
}
-(NSInteger)popListView:(NGPopListView *)popListView numberOfRowsWithIndex:(NSInteger)index
{
    if (_searchBar.isFirstResponse) {
        _searchBar.isFirstResponse = YES;
    }
    
    return ((NSArray*)[_common_pop_btnListArr objectAtIndex:index]).count;
}
-(void)popListView:(NGPopListView *)popListView  didSelected:(NSString *)str withIndex:(NSInteger)index
{
 //...请求网络
    _pageNum = 1;
    if (index == 1) {
        _selectedArea = str;
    }
    else if(index ==2)
    {
        _selectedType = str;
    }
    
    switch (self.vcType) {
        case NGVCTypeId_1:
        case NGVCTypeId_2:
        case NGVCTypeId_3:
        {
            if (index ==3)
            {
                _selectedSex = str;
            }
        }break;
        case NGVCTypeId_4:
        {
            if (index ==3)
            {
                NSArray *_arr = @[@"全部",@"今天",@"最近3天",@"最近7天",@"最近30天"];
                [_arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([(NSString *)obj isEqualToString:str]) {
                        if (idx==0) {
                            _selectedTime = @"";
                        }
                        else if (idx ==1)
                        {
                            _selectedTime = @"1";
                        }
                        else if (idx ==2)
                        {
                            _selectedTime = @"3";
                        }
                        else if (idx ==31)
                        {
                            _selectedTime = @"7";
                        }
                        else if (idx ==4)
                        {
                            _selectedTime = @"30";
                        }
                    }
                }];
            }
        }break;
        
        case 5:
            if (index ==3) {
                if ([str isEqualToString:@"全部"]) {
                    _selectedSex = @"";
                }
                else
               _selectedSex = str;
            }
            else if (index ==4)
            {
                if ([str isEqualToString:@"全部"]) {
                    _selectedZhiWei = @"";
                }
                else
                _selectedZhiWei = str;
            }
            else if (index ==5)
            {
                if ([str isEqualToString:@"全部"]) {
                    _selectedJingYan = @"";
                }
                else
                _selectedJingYan = str;
            }break;
        default:break;
    }

    [_tableView.header beginRefreshing];
}


#pragma mark -NGSearchBarDelegate 
-(void)searchBarWillBeginSearch:(NGSearchBar *)searchBar
{
    _pageNum  =1;
    NSLog(@"begin");
}

-(void)searchBarDidBeginSearch:(NGSearchBar *)searchBar withStr:(NSString *)str
{
    if (searchBar.text.length > 0) {
        [self loadMoreData];
    }
    else
    {
        [SVProgressHUD showInfoWithStatus:@"输入搜索关键字"];
    }
}



#pragma mark --UItableView delegate

float _h =0;
#define cellNoLockBgColor   [UIColor colorWithRed:1.000 green:0.961 blue:0.918 alpha:1]

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _common_list_dataSource.count > 0?_common_list_dataSource.count:1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell;
    if (_common_list_dataSource.count ==0) {
        static NSString *_nodatareusecellid = @"_nodatareusecellid";
        cell = [tableView dequeueReusableCellWithIdentifier:_nodatareusecellid];
        if (cell ==nil) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:_nodatareusecellid];
            cell.textLabel.text = @"没有数据?\n下拉刷新试试\n\n\n\n\n\n";
            cell.textLabel.numberOfLines = 0;
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.font = [UIFont systemFontOfSize:18];
            cell.textLabel.textColor = [UIColor lightGrayColor];
            cell.userInteractionEnabled = NO;
        }
        return cell;
    }
    
    NSDictionary *_dic0 = [_common_list_dataSource objectAtIndex:indexPath.row];
    NSString * str = [_dic0 objectForKey:@"yewu"];
    CGSize _new =  [ToolsClass calculateSizeForText:str :cellMaxFitSize font:cellFitfont];
    cell =  [tableView dequeueReusableCellWithIdentifier:_common_list_cellReuseId forIndexPath:indexPath];
    
    switch (self.vcType) {
        case NGVCTypeId_1:
        case NGVCTypeId_2:
        case NGVCTypeId_3:
        {
            NGSecondListCell *cell1 = (NGSecondListCell *)cell;
            [(NGSecondListCell *)cell setCellWith:_dic0 withOptionIndex:self.vcType];
            CGRect rec = cell1.lab_yewu.frame;
            rec.size.height = _new.height;
            cell1.lab_yewu.frame = rec;
            _h = _new.height + 10;
            
           NSString *tel =  [_dic0 objectForKey:@"mobile"];
            NSString *islove = [_dic0 objectForKey:@"isbook"];
            _isLoved = [islove boolValue];
             NSString *uid = [_dic0 objectForKey:@"uid"];
            ((NGSecondListCell *)cell).btnClickBlock = ^(NSInteger tag){
                if (tag == 300) {
                     [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@",tel]]];
                }
                else if (tag == 301) {
                    //检测是否登录
                    if (![[MySharetools shared]hasSuccessLogin]) {
                        return;
                    }
                    NetIsReachable;
                        NSString *tel = [[MySharetools shared]getPhoneNumber];
                    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:tel,@"username",tel,@"mobile",@"1",@"type",uid,@"id", nil];
                   NSDictionary *_d1 = [MySharetools getParmsForPostWith:dic];
                    
                    [SVProgressHUD showWithStatus:![islove boolValue] ?@"添加收藏":@"取消收藏"];
                    NSString *_url =![islove boolValue]?NSLocalizedString(@"url_my_love", @""): NSLocalizedString(@"url_my_nolove", @"");
                    
                    RequestTaskHandle *_task = [RequestTaskHandle taskWithUrl:_url parms:_d1 andSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                        [SVProgressHUD dismiss];
                        [_tableView.header beginRefreshing];
                    } faileBlock:^(AFHTTPRequestOperation *operation, NSError *error) {
                        [SVProgressHUD showInfoWithStatus:[error localizedDescription]];
                    }];
                    [HttpRequestManager doPostOperationWithTask:_task];
                }
            };
            
        }break;

        case NGVCTypeId_4:
        {
            NSString * str = [_dic0 objectForKey:@"bz"];
            CGSize _new =  [ToolsClass calculateSizeForText:str :cellMaxFitSize font:cellFitfont];
            NGJieDanListCell *cell1 = (NGJieDanListCell *)cell;
            CGRect rec = cell1.nameLab.frame;
            rec.size.height = _new.height+10;
            cell1.nameLab.frame = rec;
            _h = _new.height + 20;
            
//            BOOL _b = [[_dic0 objectForKey:@"zt"] boolValue];
//            cell.backgroundColor = _b ? [UIColor clearColor]:cellNoLockBgColor;
            [(NGJieDanListCell *)cell setCellWith:_dic0];

        }break;
            
        case NGVCTypeId_5:
        {
            [((NGZhaoPinCell*)cell)setCellWith:_dic0];
                NSString *tel =  [_dic0 objectForKey:@"phone"];
                ((NGZhaoPinCell *)cell).btnClickBlock = ^(NSInteger tag){
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@",tel]]];
                };
                
        }break;
            
        default:break;
    }

    return cell;
}

const float cellDefaultHeight = 80.0;
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_common_list_dataSource.count ==0) {
        return tableView.frame.size.height;
    }
    
    switch (self.vcType) {
        case NGVCTypeId_1:
        case NGVCTypeId_2:
        case NGVCTypeId_3:
        {
            return 50 + _h > cellDefaultHeight?50 + _h:cellDefaultHeight;
        }break;
            
        case NGVCTypeId_4:return 90;//_h + 40 > 80?_h + 40:80;
            break;
            
        case NGVCTypeId_5:return 85;break;
        default:break;
    }
    
    return cellDefaultHeight;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _selectRowIndex = indexPath.row;
    
    switch (self.vcType) {
        case NGVCTypeId_1:
        case NGVCTypeId_2:
        case NGVCTypeId_3:
        {//附近同行
//            UIStoryboard *sb = [UIStoryboard storyboardWithName:@"secondSB" bundle:nil];
//            UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"TongHDetailVC"];
//            [self.navigationController pushViewController:vc animated:YES];
            [self performSegueWithIdentifier:showTongHangVcID sender:nil];
        }break;
            
        case NGVCTypeId_4://接单
        {
            UIStoryboard *sb = [UIStoryboard storyboardWithName:@"homeSB" bundle:nil];
            NGJieDanDetailVC* vc=  [sb instantiateViewControllerWithIdentifier:@"NGJieDanDetailVCID"];
            vc.danZiInfoDic = [_common_list_dataSource objectAtIndex:_selectRowIndex];
            vc.hidesBottomBarWhenPushed = YES;
            vc.isLove = NO;
            [self.navigationController pushViewController:vc animated:YES];
        }break;
        case NGVCTypeId_5://招聘
        {
            [self performSegueWithIdentifier:showQinZhiVcID sender:nil];
        }break;
        default:break;
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_pageNum != NSNotFound && indexPath.row == _common_list_dataSource.count - 1) {
        _pageNum++;
//        [_tableView.footer beginRefreshing];
        [self loadMoreData];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:showTongHangVcID]) {
        NGTongHDetailVC *vc = [segue destinationViewController];
        vc.personInfoDic = [_common_list_dataSource objectAtIndex:_selectRowIndex];
        vc.isLoved = _isLoved;
    }
    else if ([segue.identifier isEqualToString:showZhaoPinVcID])//单子信息
    {
        NGZPPersonInfoVC *vc = [segue destinationViewController];
        vc.infoDic = [_common_list_dataSource objectAtIndex:_selectRowIndex];
    }
    else if ([segue.identifier isEqualToString:showQinZhiVcID])
    {
        NGZhaoPinDetailVC *vc = [segue destinationViewController];
        vc.infoDic = [_common_list_dataSource objectAtIndex:_selectRowIndex];
    }
}


@end
