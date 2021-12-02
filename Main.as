[Setting category="Display Settings" name="Window visible" description="To move the table, click and drag while the Openplanet overlay is visible."]
bool windowVisible = true;

class PlayerScore {
    string name;
    int points;
    int teamNum;
}

array<PlayerScore@> g_playerScores;
dictionary g_playerScoresMap = {};

void SortPlayers()
{
    // Trying to sort an array of less than 2 items will throw an index out of bounds exception
    if (g_playerScores.Length < 2) {
        return;
    }
    g_playerScores.Sort(function(a, b) {
        return a.points > b.points;
    });
}

void Render() {
    auto app = cast<CTrackMania>(GetApp());
    auto network = cast<CTrackManiaNetwork>(app.Network);
    auto server_info = cast<CTrackManiaNetworkServerInfo>(network.ServerInfo);

    if (windowVisible && app.CurrentPlayground !is null && server_info.CurGameModeStr == "TM_Teams_Matchmaking_Online") {

        int windowFlags = UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse | UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;

        UI::Begin("Match Scores", windowFlags);
        
        UI::PushStyleVar(UI::StyleVar::WindowMinSize, vec2(0, 0));
        UI::Dummy(vec2(100, 0));
        UI::PopStyleVar();

        UI::BeginGroup();

        int tableFlags = UI::TableFlags::SizingFixedFit | UI::TableFlags::Sortable;
        UI::BeginTable("scores", 2, tableFlags);

        UI::TableSetupColumn("Player", UI::TableColumnFlags::WidthStretch);
        UI::TableSetupColumn("Score", UI::TableColumnFlags::DefaultSort | UI::TableColumnFlags::PreferSortDescending | UI::TableColumnFlags::WidthFixed, 50);
        UI::TableHeadersRow();

        auto@ playground = app.CurrentPlayground;
        auto players = playground.Players;

        for (uint i = 0; i < g_playerScores.Length; i++) {
            auto player = g_playerScores[i];

            UI::TableNextRow();
            UI::TableSetColumnIndex(0);
            string color = "\\$37f";
            if (player.teamNum == 2) {
                color = "\\$e22";
            }
            UI::Text(color + Icons::Circle + "\\$z " + player.name);

            UI::TableSetColumnIndex(1);
            int points = 0;
            string pointText = "" + player.points;
            if (i != 0) {
                pointText += " (" + (player.points - g_playerScores[0].points) + ")";
            }
            UI::Text(pointText);
        }

        UI::EndTable();

        UI::EndGroup();

        UI::End();
    }    
}

void RenderMenu() {
  if(UI::MenuItem("\\$3a2" + Icons::SortNumericAsc + "\\$z Ranked Total Scores Window", "", windowVisible)) {
    windowVisible = !windowVisible;
  }
}

void Update(float dt) {
    auto app = cast<CTrackMania>(GetApp());
    auto network = cast<CTrackManiaNetwork>(app.Network);
    auto clientApi = network.PlaygroundClientScriptAPI;
    auto ui = clientApi.UI;
    auto uiSeq = ui.UISequence;
    bool isScoreDirty = false;

    if (app.CurrentPlayground !is null) {
        auto@ playground = app.CurrentPlayground;
        auto players = playground.Players;
        for (uint i = 0; i < players.Length; i++) {
            auto player = cast<CSmPlayer>(players[i]);
            auto playerName = "Player " + i;
            if (player.User !is null) {
                auto user = player.User;
                playerName = user.Name;
            }
            int points = 0;
            int teamNum = 1;
            if (player.Score !is null) {
                points = player.Score.Points;
                teamNum = player.Score.TeamNum;
            }

            if (g_playerScoresMap.Exists(playerName)) {
                auto@ thePlayerScore = cast<PlayerScore@>(g_playerScoresMap[playerName]);
                if (thePlayerScore.points != points) {
                    thePlayerScore.points = points;
                    isScoreDirty = true;
                }
                if (thePlayerScore.teamNum != teamNum && uiSeq == CGamePlaygroundUIConfig::EUISequence::Playing) {
                    thePlayerScore.teamNum = teamNum;
                }
            } else {
                auto@ newPlayerScore = PlayerScore();
                newPlayerScore.name = playerName;
                newPlayerScore.points = points;
                newPlayerScore.teamNum = teamNum;

                g_playerScores.InsertLast(@newPlayerScore);
                g_playerScoresMap[playerName] = @newPlayerScore;
                isScoreDirty = true;
            }    
        }

        if (isScoreDirty) {
            SortPlayers();
            isScoreDirty = false;
        }
    } else {
        if (!g_playerScoresMap.IsEmpty()) {
            g_playerScores.RemoveRange(0, g_playerScores.Length);
            g_playerScoresMap.DeleteAll();
        }
    }
}

void Main() {

}