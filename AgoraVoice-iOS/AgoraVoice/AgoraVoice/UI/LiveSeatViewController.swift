//
//  LiveSeatViewController.swift
//  AgoraLive
//
//  Created by CavanSu on 2020/3/23.
//  Copyright © 2020 Agora. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay

struct LiveSeatAction {
    var seat: LiveSeat
    var command: LiveSeatView.Command
}

struct LiveSeatCommands {
    var seat: LiveSeat
    var commands: [LiveSeatView.Command]
}

class SeatButton: UIButton {
    var type: SeatState = .empty {
        didSet {
            switch type {
            case .empty:            setImage(UIImage(named: "icon-invite")!, for: .normal)
            case .close:            setImage(UIImage(named: "icon-lock")!, for: .normal)
            case .normal(let user): setImage(user.info.image, for: .normal)
            }
        }
    }
    
//    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
//        return bounds
//    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initViews()
    }
    
    private func initViews() {
        type = .empty
        backgroundColor = UIColor(hexString: "#000000-0.6")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        isCycle = true
    }
}

class CommandCell: UICollectionViewCell {
    private lazy var underLine: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor(hexString: "#0C121B").cgColor
        self.contentView.layer.addSublayer(layer)
        return layer
    }()
    
    var needUnderLine: Bool = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor(hexString: "#161D27")
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.backgroundColor = UIColor(hexString: "#161D27")
    }
    
    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.textColor = UIColor(hexString: "#FFFFFF")
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        self.contentView.addSubview(label)
        return label
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.titleLabel.frame = CGRect(x: 0,
                                       y: 0,
                                       width: self.bounds.width,
                                       height: self.bounds.height)
        
        if needUnderLine {
            self.underLine.frame = CGRect(x: 5,
                                          y: self.bounds.height - 1,
                                          width: self.bounds.width - 10,
                                          height: 1)
        } else {
            self.underLine.frame = CGRect.zero
        }
    }
}

class LiveSeatView: RxView {
    enum Command {
        // 禁麦， 解禁， 封麦，下麦， 解封， 邀请，
        case ban, unban, close, forceEndBroadcasting, release, invitation
        // 申请成为主播， 主播下麦
        case application, endBroadcasting
        
        var description: String {
            switch self {
            case .ban:                  return NSLocalizedString("Seat_Ban")
            case .unban:                return NSLocalizedString("Seat_Unban")
            case .forceEndBroadcasting: return NSLocalizedString("End_Broadcasting")
            case .close:                return NSLocalizedString("Seat_Close")
            case .release:              return NSLocalizedString("Seat_Release")
            case .invitation:           return NSLocalizedString("Invitation")
            case .application:          return NSLocalizedString("Apply_For_Broadcasting")
            case .endBroadcasting:      return NSLocalizedString("End_Broadcasting")
            }
        }
    }
    
    fileprivate var commandButton = SeatButton(frame: CGRect.zero)
    fileprivate var commands = BehaviorRelay(value: [Command]())
    
    private(set) var index: Int = 0
    
    let commandFire = PublishRelay<Command>()
    
    var perspective: LiveRoleType = .audience {
        didSet {
            if commandButton.type != .empty && perspective == .audience {
                commandButton.isUserInteractionEnabled = false
            } else {
                commandButton.isUserInteractionEnabled = true
            }
        }
    }
    
    init(index: Int, frame: CGRect) {
        super.init(frame: frame)
        self.index = index
        initViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(frame: CGRect.zero)
        index = 0
        initViews()
    }
    
    func initViews() {
        backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
        
        commandButton.rx.tap.subscribe(onNext: { [unowned self] in
            switch (self.commandButton.type, self.perspective) {
            // owner
            case (.empty, .owner):
                self.commands.accept([.invitation, .close])
            case (.normal(let user), .owner):
                if user.permission.contains(.mic) {
                    self.commands.accept([.ban, .forceEndBroadcasting, .close])
                } else {
                    self.commands.accept([.unban, .forceEndBroadcasting, .close])
                }
            case (.close, .owner):
                self.commands.accept([.release])
            // broadcaster
            case (.empty, .broadcaster):
                break
            case (.normal(let user), .broadcaster):
                guard user.info == Center.shared().centerProvideLocalUser().info.value else {
                    return
                }
                self.commands.accept([.endBroadcasting])
            case (.close, .broadcaster):
                break
            // audience
            case (.empty, .audience):
                self.commandFire.accept(.application)
            case (.normal, .audience):
                break
            case (.close, .audience):
                break
            }
        }).disposed(by: bag)
        
        //commandButton.type = .close
        commandButton.imageView?.backgroundColor = .red
        
        addSubview(commandButton)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        commandButton.frame = bounds
    }
}

class LiveSeatViewController: MaskViewController {
    private let seatCount = 8
    
    private lazy var seatViews: [LiveSeatView] = {
        var temp = [LiveSeatView]()
        for i in 0 ..< seatCount {
            let seatView = LiveSeatView(index: i,
                                        frame: CGRect.zero)
            
            seatView.commands.filter { (commands) -> Bool in
                return commands.isEmpty ? false : true
            }.subscribe(onNext: { [unowned self] (commands) in
                let seat = self.seats.value[seatView.index]
                let seatCommands = LiveSeatCommands(seat: seat, commands: commands)
                self.seatCommands.accept(seatCommands)
            }).disposed(by: bag)
            
            temp.append(seatView)
            view.addSubview(seatView)
        }
        return temp
    }()
    
    lazy var seats: BehaviorRelay<[LiveSeat]> = {
        var temp = [LiveSeat]()
        for i in 0 ..< self.seatCount {
            let seat = LiveSeat(index: i, state: .close)
            temp.append(seat)
        }
        
        return BehaviorRelay(value: temp)
    }()
    
    let userAudioSilence = PublishRelay<LiveRoleItem>()
    let actionFire = PublishRelay<LiveSeatAction>()
    let seatCommands = PublishRelay<LiveSeatCommands>()
    
    var perspective: LiveRoleType = .audience
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        seats.subscribe(onNext: { (seats) in
            self.updateSeats(seats)
        }).disposed(by: bag)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let space: CGFloat = 26
        let width: CGFloat = (UIScreen.main.bounds.width - (space * 5)) / 4
        let height: CGFloat = width
        let rowCount: Int = 4
        
        for (index, item) in seatViews.enumerated() {
            let x = space + CGFloat(index % rowCount) * (space + width)
            let y = CGFloat(index / rowCount) * (height + space)
            item.frame = CGRect(x: x, y: y, width: width, height: height)
        }
    }
    
//    func activeSpeaker(_ speaker: Speaker) {
//        var agoraUid: UInt
//
//        switch speaker {
//        case .local:
//            guard let uid = ALCenter.shared().liveSession?.role.value.agUId else {
//                return
//            }
//            agoraUid = UInt(uid)
//        case .other(agoraUid: let uid):
//            agoraUid = uid
//        }
//
//        for item in seats.value where item.user != nil {
//            let seatView = self.seatViews[item.index - 1]
//            if let user = item.user, user.agUId == agoraUid {
//                seatView.renderView.startSpeakerAnimating()
//            }
//        }
//    }
}

private extension LiveSeatViewController {
    func updateSeats(_ seats: [LiveSeat]) {
        guard seats.count == seatCount else {
            assert(false)
            return
        }
        
        for (index, item) in seats.enumerated() {
            let view = seatViews[index]
            view.perspective = self.perspective
            view.commandButton.type = item.state
        }
    }
}

class CommandViewController: RxCollectionViewController {
    let commands = BehaviorRelay(value: [LiveSeatView.Command]())
    let selectedCommand = PublishRelay<LiveSeatView.Command>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        collectionView.isScrollEnabled = false
        collectionView.register(CommandCell.self, forCellWithReuseIdentifier: "CommandCell")
        collectionView.delegate = nil
        collectionView.dataSource = nil
        
        commands.bind(to: collectionView.rx.items(cellIdentifier: "CommandCell",
                                                  cellType: CommandCell.self)) { (index, command, cell) in
                                                    cell.titleLabel.text = command.description
        }.disposed(by: bag)
        
        collectionView.rx
            .modelSelected(LiveSeatView.Command.self)
            .subscribe(onNext: { [unowned self] (command) in
                self.selectedCommand.accept(command)
        }).disposed(by: bag)
    }
}
