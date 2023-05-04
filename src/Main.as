void Main() {
    startnew(CMapLoop);
}

void OnDestroyed() { Unload(); }
void OnDisabled() { Unload(); }
void Unload() { ResetChatVis(); }
void OnEnabled() {
    try {
        AwaitGetMLObjs(); // can throw outside PG, just ignore
    } catch {}
 }

// note: we actually set frame-chrono to @FrameChat -- the child of Race_Chrono
const string FrameChatId = "FrameChat";

void CMapLoop() {
    auto app = cast<CGameManiaPlanet>(GetApp());
    while (true) {
        yield();
        while (app.CurrentPlayground is null) yield();
        AwaitGetMLObjs();
        while (app.CurrentPlayground !is null) {
            UpdateChatVis();
            yield();
        }
        @FrameChat = null;
        count = 0;
    }
}

CControlBase@ FrameChat = null;

CControlBase@ FindFrameChild(CControlContainer@ parent, string[] &in path, uint ix = 0) {
    if (parent is null)
        return null;
    if (ix >= path.Length)
        return parent;

    auto childName = path[ix];
    for (uint i = 0; i < parent.Childs.Length; i++) {
        auto child = parent.Childs[i];
        if (child.IdName == childName) {
            if (i == path.Length - 1) {
                return child;
            }
            auto newParent = cast<CControlContainer>(child);
            return FindFrameChild(newParent, path, ix + 1);
        }
    }
    // no match
    return null;
}

uint count = 0;
void AwaitGetMLObjs() {
    auto app = GetApp();
    auto currPg = (app.CurrentPlayground);
    if (currPg is null) throw('null pg');
    while (currPg.Interface is null || currPg.Interface.InterfaceRoot is null) yield();
    count = 0;
    while (FrameChat is null && app.CurrentPlayground !is null) {
        sleep(50);
        if (app.CurrentPlayground is null) break;
        if (app.CurrentPlayground.Interface is null) continue;
        auto pg = app.CurrentPlayground;
        auto iface = pg.Interface;
        auto root = iface.InterfaceRoot;
        @FrameChat = FindFrameChild(root, {"FrameInGameBase", "FrameChat"});
        if (FrameChat !is null) break;
        count++;
        // if (FrameChat is null && count < 50) trace('not found');
        if (count > 50) {
            warn('ML not found, not updating ML props');
            return;
        }
    }
    startnew(UpdateChatVis);
}

void UpdateChatVis() {
    if (FrameChat is null) return;
    if (!FrameChat.IsVisible) return;
    FrameChat.Hide();
    trace('Hid the chat frame');
}

void ResetChatVis() {
    if (FrameChat is null) return;
    if (FrameChat.IsVisible) return;
    FrameChat.Show();
    trace('Showed the chat frame');
}
