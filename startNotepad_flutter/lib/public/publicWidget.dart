//公共样式
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';
import 'package:startnotepad_flutter/tools/localData.dart';
import 'package:url_launcher/url_launcher.dart';

class Publicwidget {
  static const double _toastRadius = 14;

  static const List<BoxShadow> _toastShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 12)),
  ];

  //本地存储数据
  static Future<void> saveData(String key, dynamic value) async {
    if (value is Object) {
      await LocalData.setValue(key, value);
    }
  }

  static Future<dynamic> getData(String key) async {
    return LocalData.getValue(key);
  }

  //底部弹窗
  static void showToast(BuildContext context, String message, bool isSuccess) {
    toastification.show(
      type: isSuccess ? ToastificationType.success : ToastificationType.error,
      context: context,
      title: Text(
        message,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      alignment: Alignment.bottomCenter,
      boxShadow: _toastShadow,
      borderRadius: BorderRadius.circular(_toastRadius),
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  //中间加载弹窗
  static void showLoading(BuildContext context, String message, int duration) {
    toastification.show(
      type: ToastificationType.info,
      context: context,
      title: Text(
        message,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      direction: TextDirection.ltr,
      alignment: Alignment.bottomCenter,
      showProgressBar: true,
      closeButton: ToastCloseButton(
        showType: CloseButtonShowType.onHover,
        buttonBuilder: (context, onClose) {
          return OutlinedButton.icon(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 20),
            label: const Text('关闭'),
          );
        },
      ),
      autoCloseDuration: Duration(seconds: duration),
      boxShadow: _toastShadow,
      borderRadius: BorderRadius.circular(_toastRadius),
      icon: Icon(Icons.hourglass_empty, color: Colors.black87),
    );
  }

  static Future<void> showSupportSheet(BuildContext context) async {
    const phone = '13403488056';
    const email = '13403488056@163.com';

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '联系客服',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.tonalIcon(
                    onPressed: () async {
                      final uri = Uri(scheme: 'tel', path: phone);
                      try {
                        if (!await canLaunchUrl(uri)) {
                          if (!context.mounted) return;
                          Publicwidget.showToast(context, '无法拉起系统拨号', false);
                          return;
                        }
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        Publicwidget.showToast(context, '拨号失败', false);
                      }
                    },
                    icon: const Icon(Icons.phone_outlined),
                    label: const Text('拨打电话  $phone'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.tonalIcon(
                    onPressed: () async {
                      await Clipboard.setData(const ClipboardData(text: email));
                      if (!context.mounted) return;
                      Publicwidget.showToast(context, '已复制邮箱', true);
                    },
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('复制邮箱  $email'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  //用户服务协议
  static String agreement = """
最后更新日期：2025年11月06日

一、重要提示
     请务必认真阅读本《用户服务协议》（以下简称"本协议"），特别是加粗显示的条款。一旦您下载、安装或使用《星记事》（以下简称"本应用"）及相关服务，即表示您已充分阅读、理解并同意接受本协议的全部内容。如果您不同意本协议的任何条款，请立即停止使用本应用。

二、定义
    "我们"：指 星计算网络有限公司，本应用的所有者和运营者。
    "您"：指使用本应用及相关服务的用户。
    "服务"：指我们通过本应用向您提供的各项功能和服务。

三、账户注册与安全
    注册资格：您确认在完成注册程序时，已年满18周岁或符合当地法律规定的完全民事行为能力年龄标准。
    信息真实：您应提供真实、准确、完整和最新的注册信息，并及时更新。
    账户安全：您有责任妥善保管账户信息及密码，并对使用该账户进行的所有活动承担责任。如发现任何未经授权的使用行为，应立即通知我们。
    实名认证：根据国家法律法规要求，部分服务可能需要您完成实名认证。

四、服务内容
    我们通过本应用为您提供以下服务：
    1. 记事本功能：您可以创建、编辑、删除和搜索记事本。
    2. 笔记功能：您可以创建、编辑、删除和搜索笔记。
    3. 待办事项功能：您可以创建、编辑、删除和搜索待办事项。
    4. 备忘录功能：您可以创建、编辑、删除和搜索备忘录。
    5. 日历功能：您可以创建、编辑、删除和搜索日历。
    6. 便签功能：您可以创建、编辑、删除和搜索便签。
    7. 其他功能：您可以创建、编辑、删除和搜索其他功能。
    我们保留随时修改、暂停或终止部分或全部服务的权利，恕不另行通知。
    部分服务可能需要您支付相应费用，我们将明确标注并取得您的同意。

五、用户行为规范
您承诺不得利用本应用从事以下行为：
    违反国家法律法规、社会主义制度、国家利益、公民合法权益、社会公共秩序和道德风尚；
    上传、发布或传播任何骚扰、中伤、辱骂、威胁、淫秽、暴力或其他非法内容；
    侵犯他人知识产权、商业秘密或其他合法权益；
    进行任何可能损害我们的系统或网络安全的行为；
    未经授权访问或试图访问其他用户的账户；
    利用技术手段批量注册账户，或实施任何形式的虚假交易；
    其他我们合理认为不适当的行为。
    您应自行承担因违反上述规定而直接或间接导致的任何损失、损害、责任、费用和开支。
六、隐私保护
    我们高度重视您的隐私保护。关于我们如何收集、使用、存储和共享您的个人信息，请详细阅读《隐私政策》。该政策是本协议的重要组成部分。

七、知识产权
    本应用及其所有内容（包括但不限于文本、图像、音频、视频、软件、设计和标识）的知识产权归我们或相关权利人所有。
    未经我们明确书面许可，您不得复制、修改、出租、出售、传播或创建衍生作品。

八、免责声明
    我们尽力确保服务的稳定性和安全性，但不保证服务不会中断或没有错误。
    对于因不可抗力（如自然灾害、政府行为等）或我们无法控制的原因导致的服务中断或数据丢失，我们不承担责任。
    您使用本应用下载或获取任何材料的行为均出于您自己的决定，并自行承担风险。

九、服务变更与终止
    我们可能根据需要随时变更、中断或终止部分或全部服务。
    如您违反本协议，我们有权暂停或终止向您提供服务，并保留追究法律责任的权利。
    您有权通过注销账户的方式终止使用本应用。

十、适用法律与争议解决
    本协议的订立、执行和解释均适用中华人民共和国法律。
    因本协议引起的或与本协议有关的任何争议，双方应首先通过友好协商解决；协商不成的，任何一方均有权将争议提交[公司所在地]有管辖权的人民法院诉讼解决。

十一、其他条款
    本协议的任何条款被认定为无效或不可执行，不影响其他条款的效力。
    本协议构成您与我们之间就使用本应用达成的完整协议。

十二、联系我们
    如果您对本协议或本应用有任何疑问、意见或建议，请通过以下方式联系我们：
    客服邮箱：[1340348056@163.com]
    联系电话：[13403488056]
    联系地址：[山西省运城市]





    
  """;
}
